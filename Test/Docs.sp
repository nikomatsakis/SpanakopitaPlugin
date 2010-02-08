___ Documentation For Spanakopita Markup _____________________________

Spanakopita markup is designed, more or less, after the informal
rules that I generally use when writing text files, though
influenced by the [[txt2tags system @ http://txt2tags.sourceforge.net/]].

______ Headings ______________________________________________________

Headings are produced by placing three or more underscores at the
start of a line.  Any trailing underscores are then ignored.

**Example:** 
||
    {
        ___ Heading Level 1 _________        
    } 
|
    ___ Heading Level 1 ___
|| ||
    {
        ______ Heading Level 2 ______
    }
|
    ______ Heading Level 2 ______
|| ||
    {
        _________ Heading Level 3 ___
    }
|
    _________ Heading Level 3 ___
||

______ Indentation: Block Quoting, etc. ______________________________

First of all, indentation is significant. I suggest that you edit {.sp}
files using TextMate's {Soft Tabs} feature and avoid including tabs in your
files (the menu option {Text > Convert > Tabs to Spaces} may be helpful
here). Generally speaking indentation can be used to create block quotes
but it is also used to nest tables within tables.

**Examples:**
||
    {
        Some text.
            Some indented text.
                Even more indented text.
            Unindented text.
        Some unindented text.
        
        A new paragraph.  Note the blank line.
    }
|
    Some text.
        Some indented text.
            Even more indented text.
        Unindented text.
    Some unindented text.
        
    A new paragraph.  Note the blank line.
||

______ Beautifiers ___________________________________________________

A paragraph is just a bunch of text followed by a blank line.  Within a paragraph, there are several beautifiers that can be used:
|| {**Bold**} | **Bold** ||
|| {//Italics//} | //Italics// ||
|| {__Underline__} | __Underline__ ||
|| {--Strikeout--} | --Strikeout-- ||
|| {{Verbatim}} | {Verbatim} ||
Note the last one.  To produce an em dash, use three dashes
like this: {---}, which will produce the symbol "---".

Verbatim text is somewhat special.  First, it disables markup by default
(though it can be re-enabled, see the section on Escaping).  Second, if
you follow a curly brace (\{) with a newline and an indent, it becomes
a code block, as shown here:
||
    {
        {
            int main() {
                return 0;
            }
        }
    }
|
    {
        int main() {
            return 0;
        }
    }
||
Note that curly braces in any verbatim section //must// be balanced unless
preceded by a backslash:
||
    {{Unbalanced curly: \\\{}}
|
    {Unbalanced curly: \{}
||

______ Lists _________________________________________________________

Lists are pretty easy. Just start a link with a single dash {-}. If the
text for a list item is longer than one line, then subsequent lines should
be indented by two spaces to line up (note that TextMate's {Reformat
Paragraph} ({^Q}) command does this by default).

**Example:**
||
    {
        - A list item.
        - Another list item.
            - An indented list.
                - A doubly indented list.
                  This list item spans two lines.
            - To unindent, just, well, do it.
            
              Also, list items can have multiple paragraphs.
              Note that the start of this parapgraph was 
              indented to line up with the other members of
              the list item. 
        This text is not part of the list.
    }
|
    - A list item.
    - Another list item.
        - An indented list.
            - A doubly indented list.
              This list item spans two lines.
        - To unindent, just, well, do it.
    
          Also, list items can have multiple paragraphs.
          Note that the start of this parapgraph was 
          indented to line up with the other members of
          the list item. 
    This text is not part of the list.
||

______ Images ________________________________________________________

Embedding images is done by enclosing the URL in square braces ({[} and
{]}).

**Examples:**
|| {[spanakopita.jpg]} | [spanakopita.jpg] ||

______ Links _________________________________________________________

Links are similar to images but they use double braces ({[[} and {]]}). The
(optional) link text is separated from the URL by an {@} sign.
If the link text is omitted, then it is generated from the URL by
dropping any extension.

**Examples:**
|| 
    {[[a link to this document @ Docs.sp]]} 
| 
    [[a link to this document @ Docs.sp]] 
|| ||
    {[[@Docs.sp]]}
|
    [[@Docs.sp]]
|| ||
    {[[Absolute URLs are OK too @ http://www.google.com]]}
|
    [[Absolute URLs are OK too @ http://www.google.com]]
|| ||
    {[[@http://www.google.com]]}
|
    [[@http://www.google.com]]
||

______ Tables ________________________________________________________

Table rows are enclosed in double pipe symbols {||}.  Cells
are separated using a single {|}.  Subsequent rows are joined into a single
table.  A cell can contain either one line of text or an indented
section.  The latter can be used to create nested tables:

**Examples:**
||
    {
        || a | b | c ||
        || d | e | f ||
    }
|
    || a | b | c ||
    || d | e | f ||
|| ||
    {
        || a
        |  b
        |  c
        || 
        || d
        |  e
        |  f
        ||        
    }
|
    || a
    |  b
    |  c
    || 
    || d
    |  e
    |  f
    ||        
|| ||
    {
        || 
            || a0 | a1 ||
            || b0 | b1 ||
        |  b
        |  c
        || 
        || d
        |  e
        |  f
        ||        
    }
|
    || 
        || a0 | a1 ||
        || b0 | b1 ||        
    |  b
    |  c
    || 
    || d
    |  e
    |  f
    ||        
||

______ Escaping ______________________________________________________

In general any character can be escaped by preceding it with a backslash
(\\).  This disables any markup associated with that character.
To insert a literal backslash, simply use two in a row (\\\\).

However, in a verbatim section, the escaping rules are reversed.
Markup is //disabled// by default and only //enabled// by a backslash.
This allows you to embed images and links or highlight content.  The only
exception are the characters \{, \}, and the backslash \\ itself,
which are still significant in verbatim text.

**Examples:**
||
    {**Bold text.**}
|
    **Bold text.**
|| ||
    {\\**Not bold text.\\**}
|
    \**Not bold text.\**
|| ||
    {{Verbatim section so **bold text** is not enabled.}}
|
    {Verbatim section so **bold text** is not enabled.}
|| ||
    {{But it can be explicitly \\**enabled\\**.}}
|
    {But it can be explicitly \**enabled\**.}
|| ||
    {{Escaped braces \\\{, \\\}, and double escapes \\\\ in a verbatim 
    section.}}
|
    {Escaped braces \{, \}, and double escapes \\ in a verbatim 
    section.}
|| ||
    {{\\[[String \\@ http://java.sun.com/j2se/1.5.0/docs/api/java/lang/String.html\\]]}}
|
    {\[[String \@ http://java.sun.com/j2se/1.5.0/docs/api/java/lang/String.html\]]}
|| 