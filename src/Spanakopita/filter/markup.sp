Spanakopita markup tool.  The markup is loosely based on http://txt2tags.sf.net.

Blank lines are significant.  A blank line ends the current paragraph.  Two blank
lines end any nested structures, such as lists and the like.

Indentation is significant.  More indentation than the previous line 
will cause block indentation.  In a list, indentation creates sublists.

Comments and special:
  ## At the beginning of a line is for special stuff.
  ## TABLE_OF_CONTENTS  

Headers:
  ___ Level 1 __________________________________________________________
  ______ Level 2 _______________________________________________________  
  _________ Level 3 ____________________________________________________
  Any number of trailing underscores is permitted.

Escaping:
  \x is just 'x'
  \\ is '\\'

Beautifiers:
  //italics//
  **bold**
  {code}
  __underline__
  --strikeout--

  Beautifiers can be used **inline**, or they can use **
    indentation to apply to multiple lines, like here.
  **

Lists:
  - Unordered Lists begin with "-"
  + Ordered Lists begin with "+"

Verbatim Text (disables beautifiers etc but also escaping):
  """
  Everything between the triple-quotes.  Triple quotes must appear alone
  the line.  Indentation up to the indentation of the triple quotes is
  removed.
  """

Tables:
  || Begins a row and | separates cells within a row

URLs:
  absolute:URLs may be embedded just so.

Meta-discussion about links:
  In the examples that follow, a link may either be an absolute URL
  or a relative path.  Relative paths may include spaces etc and we will
  do our best to apply URL escaping in all cases.  

Images:
  [link] includes an image at the path ``link``.  The image will be 
  be linked to its source in such a way that clicked it will cause the
  source to be "opened".

Links:
  [[Some Text]] links to "Some Text.sp" with the link text "Some Text"
  [[Some Text @ link]] links to ``link`` with the link text "Some Text".
  [[[link] @ link]] links to ``link`` with an image.
