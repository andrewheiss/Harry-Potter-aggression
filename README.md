# Harry Potter Aggression Data

Someone collected [a fantastic dataset](https://docs.google.com/spreadsheets/d/1heSMqYzYnL5bS0xiZ2waReUMLKIxHce5MMsQxzhgaA8/edit#gid=1825799110) of all the instances where characters in the Harry Potter books acted aggressively, resulting in lots of interesting data visualizations. For instance, it appears that Harry is quite a sociopath, with more aggressive actions than any other character:

![Top 5 aggressive characters](https://raw.githubusercontent.com/andrewheiss/Harry-Potter-aggression/master/images/top_5.png)

However, this does not account for the actual time the characters appear in the books. Harry is the subject of the series and the whole narrative centers around him, so it's logical that he would have the most aggressive actions.

We can adjust for "screen time" by counting the number of mentions each character gets in the series. I downloaded the [full text of the Harry Potter series](http://www.readfreeonline.net/Author/J._K._Rowling/Index.html) and did a crude search to find the number of paragraphs each character was mentioned in each book ([raw data](https://github.com/andrewheiss/Harry-Potter-aggression/blob/master/harry_potter_aggression_full.csv)). With this  data on mentions, we can calculate the proportion of aggressive actions per mention in the books.

Using this data, the top 5 from before are far less aggressive. More obviously bad characters like boggarts, the basilisk, Nagini, and random death eaters are the most aggressive:

![Aggression adjusted for mentions](https://raw.githubusercontent.com/andrewheiss/Harry-Potter-aggression/master/images/adjusted.png)
