This document demonstrates some of the features of
{filter.py}. You can write inline code sections like this:
{
    void src() {
        int *p;
        return;
    }
}
or you can just highlight a variable like {int *p}.  You can also
do the usual **bold**, //italic//, --struck out--, and even __underlined__ text.

Images are with square brackets: [t2tpowered.png] and links are with [[double brackets @
Test2.sp]].  Just linking to an sp file like [[Test2]] is particularly short.
    
You should be able to create lists:
- One Item
  
  A continuation of the first item that is very long so it must span multiple lines, but it's 
  still the same item because it is indented to match the text after the bullet.
- Two Items
- Three Items, and this one is very long so it must span multiple lines, but it's still the same
  item because it is indented to match the text after the bullet.

It is also possible to make numbered lists:
# First item.
# Second item.
# Third item.

It should be possible to nest lists:
- A
    - i
        # 1
        # 2
        # 3
    - ii
- B
    - i
Note that typing here is outside the list.

Finally, we can make tables:
|| a | b | c | d ||
|| e | f | g | h ||
and text that comes after a table works just fine.

There is some flexibility with the formatting:
||  a
|   b
|   c
|   d ||
||  e
|   f
|   g
|   h ||
and text that comes after a table works just fine.

In fact, by indenting after a cell, there is quite a lot of flexibility:
||  
    a
|   
    b
|   
    c
|   
    d
||
||  
    || this way permits | nested tables ||
    || as | well ||
|   f
|   g
|   h
||