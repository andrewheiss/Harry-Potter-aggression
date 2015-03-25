#----------------
# Load packages
#----------------
library(RCurl)
library(dplyr)
library(tidyr)
library(stringr)
library(ggplot2)
library(grid)
library(Cairo)


#-------------------
# Helper functions
#-------------------
# Nice clean, stripped-down theme
theme_clean <- function(base_size=12, base_family="Source Sans Pro Light") {
  ret <- theme_bw(base_size, base_family) + 
    theme(panel.background = element_rect(fill="#ffffff", colour=NA),
          axis.title.x=element_text(vjust=-0.2), axis.title.y=element_text(vjust=1.5),
          title=element_text(vjust=1.2, family="Source Sans Pro Semibold"),
          panel.border = element_blank(), axis.line=element_blank(),
          panel.grid=element_blank(), axis.ticks=element_blank(),
          legend.position="bottom", 
          axis.title=element_text(size=rel(0.8), family="Source Sans Pro Semibold"),
          strip.text=element_text(size=rel(1), family="Source Sans Pro Semibold"),
          strip.background=element_rect(fill="#ffffff", colour=NA),
          panel.margin.y=unit(1.5, "lines"))
  
  ret
}

# Append spaces to labels to fake right margin/padding
add.spaces <- function(x) {
  return(as.character(paste0(x, "   ")))
}

# Select all the text for a specific book
get_chunk <- function(x) {
  # The book name passes as a number, not text...
  book.name <- nice.books[x]
  filter(full.text, book==book.name)$text
}

# Count the number of times a name appears in a vector of text
count.name <- function(x, regex) {
  grepl(regex, x)
}

# Make the book names from the scraped full text match the aggression data
clean.book.names <- function(x) {
  ret <- gsub("sorcerers", "sorcerer's", tolower(sub("Harry Potter and ", "", x)))
  ret
}


#------------
# Load data
#------------
# URL to the fantastic data
data.url <- "https://docs.google.com/spreadsheets/d/1heSMqYzYnL5bS0xiZ2waReUMLKIxHce5MMsQxzhgaA8/export?format=csv&gid=384008866"

# Book names
nice.books <- c("The Sorcerer's Stone", "The Chamber of Secrets", 
                "The Prisoner of Azkaban", "The Goblet of Fire", 
                "The Order of the Phoenix", "The Half-Blood Prince", 
                "The Deathly Hallows")

# Load and rearrange the data
hp <- read.csv(textConnection(getURL(data.url)), as.is=TRUE) %>% 
  select(1:13) %>%  # Only get the first 13 columns
  select(-c(g_e_m_n, evil, creature, tot)) %>%  # Get rid of other columns
  gather(book, aggressions, -c(Name, abb)) %>%
  mutate(book = factor(book, levels=levels(book), labels=nice.books, ordered=TRUE),
         book.rev = factor(book, levels=rev(levels(book)), ordered=TRUE))

# Load and clean full text from Harry Potter books
full.text <- read.csv("hp-corpus/hp-full.csv", stringsAsFactors=FALSE) %>%
  mutate(text = tolower(text),
         book = factor(clean.book.names(book), 
                       levels=tolower(levels(hp$book)), 
                       labels=levels(hp$book),
                       ordered=TRUE)) %>%
  filter(text != "") %>% filter(text != "\n")

# Load search strings
searches <- read.csv("names_with_regex.csv", stringsAsFactors=FALSE) %>%
  select(-c(abb, search))

# Calculate book length
num.paragraphs <- full.text %>% group_by(book) %>% summarize(paragraphs = n())

# Count all instances of each search string in each book (takes a while)
mentions <- hp %>%
  left_join(searches, by="Name") %>%
  rowwise() %>%
  summarize(mentions = sum(sapply(get_chunk(book), FUN=count.name, regex=regex)),
            Name = Name, book = book) %>%
  mutate(book = factor(book, labels=nice.books, ordered=TRUE))

# Combine all the fancy new data
hp.full <- hp %>% 
  left_join(num.paragraphs, by="book") %>%
  left_join(mentions, by=c("Name", "book")) %>%
  mutate(agg.per.mention = ifelse(mentions == 0, 0, aggressions / mentions),
         mentions.per.p = mentions / paragraphs,
         agg.weighted = aggressions / mentions.per.p) %>%
  filter(agg.per.mention < 1.1) %>%
  filter(mentions > 10)

write.csv(select(hp.full, -book.rev), 
          file="harry_potter_aggression_full.csv", row.names=FALSE)

#------------
# Plot data
#------------
# Find most aggressive characters
hp.full %>% group_by(Name) %>% summarize(Aggressions = sum(aggressions)) %>% 
  arrange(desc(Aggressions)) %>% head(5) -> most.aggressive

# Rearrange data for plotting
plot.data <- hp.full %>%
  filter(Name %in% most.aggressive$Name) %>%
  mutate(Name = factor(Name, levels=most.aggressive$Name, ordered=TRUE),
         Name.rev = factor(Name, levels=rev(levels(Name)), 
                           labels=add.spaces(rev(levels(Name))), ordered=TRUE)) %>%
  group_by(Name.rev, book.rev) %>%
  summarize(aggr = sum(aggressions))

# Plot top 5
ggplot(plot.data, aes(x=book.rev, y=aggr, fill=Name.rev)) + 
  geom_bar(stat="identity", position="dodge") + 
  geom_hline(yintercept=seq(10, 50, by=10), colour="#ffffff", size=0.25) + 
  coord_flip() + 
  labs(x=NULL, y="Instances of aggression", 
       title="Most aggressive characters in the Harry Potter series") + 
  scale_fill_manual(values=c("#915944", "#9BAB9C", "#692521", "#CAAA17", "#B51616"), 
                    guide=guide_legend(reverse=TRUE), name="") + 
  theme_clean() + theme(legend.key.size = unit(0.5, "lines")) -> nice.plot

# Save plot
ggsave(nice.plot, filename="images/top_5.png", width=7, height=5, units="in")
ggsave(nice.plot, filename="images/top_5.pdf", width=7, height=5, units="in", 
       device=cairo_pdf)



# Plot the characters that are most likely to be aggressive when mentioned
plot.data <- hp.full %>% 
  group_by(Name) %>% 
  summarize(aggr = mean(agg.per.mention)) %>% 
  arrange(desc(aggr)) %>% head(15) %>%
  mutate(Name = factor(Name, levels=Name, ordered=TRUE),
         Name.rev = factor(Name, level=rev(levels(Name)), ordered=TRUE)) %>%
  select(-Name)

# Get the data from the original top 5 aggressive characters
original.plot <- hp.full %>%
  filter(Name %in% most.aggressive$Name) %>%
  mutate(Name = factor(Name, levels=most.aggressive$Name, ordered=TRUE),
         Name.rev = factor(Name, levels=rev(levels(Name)), 
                           labels=add.spaces(rev(levels(Name))), ordered=TRUE)) %>%
  group_by(Name.rev) %>%
  summarize(aggr = mean(agg.per.mention))

# Combine the two sets of data
combined.plot.data <- rbind(plot.data, original.plot)

# Plot!
ggplot(combined.plot.data, aes(x=Name.rev, y=aggr)) + 
  geom_bar(stat="identity", position="dodge") + 
  geom_hline(yintercept=seq(0.1, 0.5, by=0.1), colour="#ffffff", size=0.25) + 
  geom_vline(xintercept=15.5, colour="red", size=1) + 
  labs(x=NULL, y="Probability of being aggressive when mentioned") + 
  coord_flip() + theme_clean() -> full.plot

# Save plot
ggsave(full.plot, filename="images/adjusted.png", width=7, height=5, units="in")
ggsave(full.plot, filename="images/adjusted.pdf", width=7, height=5, units="in", 
       device=cairo_pdf)
