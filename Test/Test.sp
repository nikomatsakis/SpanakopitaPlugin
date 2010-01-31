This document demonstrates some of the features of
{filter.py}. You can write inline code sections like this:
{
    void src() {
        int *p;
        return;
    }
}
or you can just highlight a variable like {int *p}.

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
Let's see how that looks.