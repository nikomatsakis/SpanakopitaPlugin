___ A Test Document __________________________________________________

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
You can ignore characters with \\: so \*\*bold\*\* just inserts asterixes.

    Indented text will be "blockquoted".
        Of course there might be more than one level of blockquote.
    No problem at all.  It should be possible to use funky characters
    like < and & as well as unicode like α, β, and γ.

Images are with square brackets: [spanakopita.jpg] and links are with [[double
brackets @ Test2.sp]]. If you omit the description, then a default one is
provided based on the file name (like here [[@Test2.sp]]) or the absolute URLs
(like [[ @ http://www.google.com]]). Note that spaces around the \@ sign are not
significant.

______ Code __________________________________________________________

Code sections are actually a kind of "reverse markup".  When entering
into an inline code section like {this one, then magic characters 
like ** or @ are normally ignored}, but you can use backslashes
{to \**temporarily \//enter\// markup mode\**}.  

You can also make links:
{
    class \[[Foo \@ Test2.sp\]] {
    }
}

______ Lists _________________________________________________________

You should be able to create lists:
- One Item
  
  A continuation of the first item that is very long so it must span multiple
  lines, but it's still the same item because it is indented to match the text
  after the bullet.
- Two Items
- Three Items, and this one is very long so it must span multiple lines, but it's
  still the same item because it is indented to match the text after the bullet.

It should be possible to nest lists:
- A
    - i
        - 1
        - 2
        - 3
    - ii
- B
    - i
Note that typing here is outside the list.

______ Tables ________________________________________________________

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
|| ||  
    || this way permits | nested tables ||
    || as | well ||
|   f
|   g
|   h
||
||
    p 
|   q
|   r
|   s 
||