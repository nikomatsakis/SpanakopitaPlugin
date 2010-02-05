#!/usr/bin/env python

"""
Spanakopita markup tool.  The markup is loosely based on a combination of
http://txt2tags.sf.net with Python's concept of significant whitespace.

Blank lines and indentation are significant. More indentation than the previous
line will cause block indentation. In a list, indentation creates sublists. I
strongly suggest avoiding tabs and using only spaces (Soft Tabs, in 
TextMate-speak), although in theory the code should work so long as you don't
mix them up.

Comments and special:
    ## At the beginning of a line is for special stuff.
    ## TABLE_OF_CONTENTS  

Headers:
    ___ Level 1 __________________________________________________________
    ______ Level 2 _______________________________________________________  
    _________ Level 3 ____________________________________________________
    Any number of trailing underscores is permitted.

Escaping:
    Backslash generally acts as an escape-character.

Beautifiers:
    //italics//
    **bold**
    __underline__
    --strikeout--

    Beautifiers can only be used **inline**.

Code:
    Code can be designated using { and }, either {inline} or in a block:
    {
        void aCodeBlock() {
        
        }
    }
    Links are still supported within code but all other markup is 
    disabled.

Lists:
    Lists begin with "-":
        - This
            - Is
        - A
        - List
    We only support numbered lists.

Tables:
    Place || at the beginning and end of a row.  Use | to separate
    cells within a row.  Cells can either be defined inline:
        || r1 c1 | r1 c2 | r1 c3 ||
        || r2 c1 | c2 c2 | r2 c3 ||
    Or using indentation:
        ||
            r1 c1
        |
            r1 c2
        |   
            r1 c3 
        ||
    You can also mix and match on a per-cell basis.  The advantage
    of using indentation is that it supports nested tables.

Meta-discussion about links:
    In the examples that follow, a link may either be an absolute URL
    or a relative path.  Relative paths may include spaces etc and we will
    do our best to apply URL escaping in all cases.  

Images:
    [link] includes an image at the path ``link``.  The image will be 
    be linked to its source in such a way that clicked it will cause the
    source to be "opened".

Links:
    [[Some Text]] links to "Some Text.sp" with the link text "Some Text".
    [[http://an.absolute.url/]] should work as well.
    [[Some Text @ link]] links to {link} with the link text "Some Text".
    [[[link] @ link]] links to {link} with an image.
"""

import sys, re, urllib

DEBUG = False

# ___ Ast Classes ______________________________________________________

class Ast(object):
    # Abstract.
    def __init__(self, pos):
        self.pos = pos
        pass
        
    @property
    def tag(self):
        return self.__class__.__name__
        
    def __str__(self):
        return "%s()" % (self.tag)
        
class LeafAst(Ast):
    def __init__(self, pos):
        super(LeafAst, self).__init__(pos)
        self.children_a = ()
        
    def dump(self, indent, out):
        out.write("%s%s:\n" % (indent, self))
        
class ParentAst(Ast):
    def __init__(self, pos):
        super(ParentAst, self).__init__(pos)
        self.children_a = []
        
    def append_child(self, a_node):
        self.children_a.append(a_node)

    def rstrip_text(self):
        if self.children_a and isinstance(self.children_a[-1], Text):
            u_text = self.children_a[-1].u_text.rstrip()
            if not u_text:
                self.children_a[-1:] = [] # Remove last entry
            else:
                self.children_a[-1].u_text = u_text
        
    def append_text(self, pos, u_text):
        if self.children_a and isinstance(self.children_a[-1], Text):
            self.children_a[-1].u_text += u_text
        else:
            self.append_child(Text(pos, u_text))

    def to_html(self, out):
        out.write('<%s>\n' % self.html)
        for c in self.children_a: c.to_html(out)
        out.write('</%s>\n' % self.html)        
        
    def dump(self, indent, out):
        out.write("%s%s:\n" % (indent, self))
        cindent = indent + "  "
        for c in self.children_a:
            c.dump(cindent, out)
            
def escape_text(u_text):
    unescaped = re.compile(ur"[a-zA-Z0-9./,;: (){}\[\]*+-]")
    def filter(u_char):
        if unescaped.match(u_char): 
            return u_char.encode('ASCII')
        return "&#x%04x;" % ord(u_char)
    return "".join(filter(u) for u in u_text)
            
class Html(ParentAst):
    html = "html"

class Body(ParentAst):
    html = "body"

class Text(LeafAst):
    def __init__(self, pos, u_text):
        super(Text, self).__init__(pos)
        self.u_text = u_text        
        
    def to_html(self, out):
        out.write(escape_text(self.u_text))
        
    def __str__(self):
        return "%s(text=%s)" % (self.tag, self.u_text)
    
class Para(LeafAst):
    def to_html(self, out):
        out.write("<p>")
            
class Indented(ParentAst):    
    html = "blockquote"

class Code(ParentAst):
    html = "pre"

class Header(ParentAst):
    def __init__(self, pos, level):
        super(Header, self).__init__(pos)
        self.level = level
        
    def to_html(self, out):
        out.write('<h%d>' % self.level)
        for c in self.children_a: c.to_html(out)
        out.write('</h%d>' % self.level)
    
class Beautified(ParentAst):
    # Abstract.
    def to_html(self, out):
        out.write('<%s>' % self.html)
        for c in self.children_a: c.to_html(out)
        out.write('</%s>' % self.html)
    
class Italicized(Beautified):
    html = "i"
    
class Bolded(Beautified):
    html = "b"
    
class Monospaced(Beautified):
    html = "tt"
    
class Underlined(Beautified):
    html = "u"
    
class Struckout(Beautified):
    html = "strike"
    
class ListItem(ParentAst):
    def to_html(self, out):
        out.write('\n<li> ')
        for c in self.children_a: c.to_html(out)

class List(ParentAst):
    # Abstract.  Children: list items.
    pass
            
class OrderedList(List):
    html = "ol"
    
class Table(ParentAst):
    # Children: table rows.
    html = "table"
    
    def to_html(self, out):
        out.write('<table border="1">\n')
        for c in self.children_a: c.to_html(out)
        out.write('</table>\n')
    
class TableRow(ParentAst):
    # Children: table columns.
    html = "tr"
    
class TableCell(ParentAst):    
    # Children: misc elems.
    html = "td"

class Image(LeafAst):
    def __init__(self, pos):
        super(Image, self).__init__(pos)
        self.url = None # must be set at some point
        
    def to_html(self, out):
        out.write('<img src="%s">' % self.url)
        #out.write('<object data="%s"></object>' % self.url)
                
    def __str__(self):
        return "%s(url=%s)" % (self.tag, self.url)
        
class Link(ParentAst):
    def __init__(self, pos):
        super(Link, self).__init__(pos)
        self.url = None # must be set at some point

    def to_html(self, out):
        out.write('<a href="%s">' % self.url)
        for c in self.children_a: c.to_html(out)
        out.write('</a>')

    def __str__(self):
        return "%s(url=%s)" % (self.tag, self.url)

# ___ Lexer ____________________________________________________________
#
# Newlines and whitespace are handled as follows: 
#
#   Ignorable whitespace generates the token SPACE.  This 
#   includes a single newline which does not change the indentation level.
#
#   Two or more consecutive newlines generates the token BLANK_LINE.
#
#   In addition, whenever a newline is followed by a new level of 
#   indentation, one or mode INDENT or UNDENT tokens are produced.
    
# Applied within lines (order is significant):
WITHIN_REGULAR_EXPRESSIONS = [
    ('AT', re.compile(r'@')),

    ('EMDASH', re.compile(r'---')),

    ('ITAL', re.compile(r'//')),
    ('BOLD', re.compile(r'\*\*')),
    ('UNDER', re.compile(r'__')),
    ('STRIKE', re.compile(r'--')),

    ('TABLE_ROW', re.compile(r'\|\|')),
    ('TABLE_CELL', re.compile(r'\|')),

    ('L_CURLY', re.compile(r'{')),
    ('R_CURLY', re.compile(r'}')),

    ('L_SQUARE_SQUARE', re.compile(r'\[\s*\[')),
    ('R_SQUARE_SQUARE', re.compile(r'\]\s*\]')),
    
    ('L_SQUARE', re.compile(r'\[')),
    ('R_SQUARE', re.compile(r'\]'))
]

# Checked only at the start of a line:
START_REGULAR_EXPRESSIONS = [
    ('HEADER', re.compile(r'___+')),
    ('BULLET', re.compile(r'-(?!-)')),
]

class Token(object):
    def __init__(self, tag, u_text):
        self.tag = tag
        self.u_text = u_text
        
    def __str__(self):
        return "%s(%s)" % (self.tag, self.u_text.encode("utf-8"))
        
class Lexer(object):
    
    def __init__(self, u_text):
        self.u_text = u_text
        self.eol = True
        self.pos = 0
        self.indent = 0 # Indent of current line.
        self.indents = [0] # Indents for which we have issued tokens.
        self.token = None
        self.verbatim_mode = 0
        self.next()
        
    def skip_space(self):
        newlines = 0
        len_text = len(self.u_text)
        p = self.pos
        
        while p < len_text and self.u_text[p].isspace():
            if self.u_text[p] == u"\n":
                self.indent = 0
                newlines += 1
            elif newlines:
                self.indent += 1
            p += 1
            
        if newlines >= 2: # At least one blank line.
            tag = 'BLANK_LINE'
        else:
            tag = 'SPACE'
        self.token = Token(tag, self.u_text[self.pos:p])
        self.pos = p
        self.eol = (newlines >= 1)
        return self.token
        
    def check_regexp(self, tag, regexp):
        mo = regexp.match(self.u_text, self.pos)
        if mo:
            self.token = Token(tag, mo.group(0))
            self.pos += len(mo.group(0))
            return True
        return False
        
    def skip_to_eol(self):
        # Advances pos to the end of the line and loads next token.  Returns skipped text.
        p = self.pos
        while p < len(self.u_text) and self.u_text[p] != u'\n':
            p += 1
        u_result = self.u_text[self.pos:p]
        self.pos = p
        return u_result
        
    def is_word(self, c):
        return not (c.isspace() or c in u"_-*/\\{}[]|\n")
        
    def next(self):
        self._next()        
        if DEBUG: sys.stderr.write("%s\n" % (self.token,))
        return self.token
        
    def push_indentation_level(self, rel_amnt):
        """
        Pushes an indentation level to rel_amnt more than it is now.  
        When the indentation drops lower, an UNDENT token will be generated.
        Used for bullet lists.
        """
        self.indent += rel_amnt
        self.indents.append(self.indent)
        
    def start_verbatim_mode(self):
        assert not self.verbatim_mode 
        self.verbatim_mode = 1
        
    def _next(self):
        if self.pos >= len(self.u_text):
            if len(self.indents) > 1:
                self.indents.pop()
                self.token = Token('UNDENT', u"")
            else:
                self.token = Token('EOF', u"")
            return 
            
        u_chr = self.u_text[self.pos]
        
        # Whitespace:
        if self.u_text[self.pos].isspace():
            self.skip_space()
            return
            
        # Adjust indentation:
        if self.indent != self.indents[-1]:
            if self.indent > self.indents[-1]:
                self.token = Token('INDENT', u"")
                self.indents.append(self.indent)
                return
            elif self.indent < self.indents[-1]:
                self.indents.pop()
                self.token = Token('UNDENT', u"")
                return
                
        if self.verbatim_mode:
            self.verbatim_next()
        else:
            self.non_verbatim_next()
            
    def verbatim_next(self):
        u_char = self.u_text[self.pos]

        # Check for escape characters:
        if u_char == u"\\" and self.pos + 1 < len(self.u_text):
            self.pos += 1
            
            # Escaped braces are just text:
            u_next_char = self.u_text[self.pos]
            if u_next_char in [u"{", u"}"]:
                self.pos += 1
                self.token = Token('TEXT', u_char)
                return
                
            # But otherwise escaped characters are markup:
            self.non_verbatim_next()
            return
            
        # Count matching braces:            
        if u_char == u"{":
            self.pos += 1
            self.verbatim_mode += 1
            self.token = Token('TEXT', u_char)
            return            
        if u_char == u"}":
            self.pos += 1
            self.verbatim_mode -= 1
            if self.verbatim_mode:
                self.token = Token('TEXT', u_char)
            else:
                self.token = Token('R_CURLY', u_char)
            return
                
        # Otherwise just return as text:
        self.next_word()

    def non_verbatim_next(self):
        # Check for escape character:
        if self.u_text[self.pos] == u"\\" and self.pos + 1 < len(self.u_text):
            self.token = Token('TEXT', self.u_text[self.pos + 1])
            self.pos += 2
            return
        
        # Check for characters only significant at the start of the line:
        if self.eol:
            for (tag, regexp) in START_REGULAR_EXPRESSIONS:
                if self.check_regexp(tag, regexp):
                    return
            self.eol = False
                    
        # Check for all special characters:
        for (tag, regexp) in WITHIN_REGULAR_EXPRESSIONS:
            if self.check_regexp(tag, regexp):
                return 
                
        # Just accumulate one word of text:
        self.next_word()
        
    def next_word(self):
        p = self.pos + 1
        while p < len(self.u_text) and self.is_word(self.u_text[p]):
            p += 1
        self.token = Token('TEXT', self.u_text[self.pos:p])
        self.pos = p
        return 
    
    @property
    def cur_line_number(self):
        return self.u_text[:self.pos].count('\n') + 1
        
    @property
    def cur_column(self):
        if self.cur_line_number == 1:
            return self.pos
        return (self.pos - self.u_text[:self.pos].rindex('\n')) + 1
        
    def require(self, tags):
        if not self.token.tag in tags:
            raise ParseError(self, tags)

    def is_a(self, tag):
        return self.token.tag == tag

# ___ Parser (Recursive Descent) _______________________________________

def parse(inputstream):
    """ Returns an Ast or else throws a ParseError. """    
    bytes = inputstream.read()
    u_text = bytes.decode("utf-8") # XXX Search for an encoding string a la emacs
    lexer = Lexer(u_text)
    a_html = Html(lexer.pos)
    a_body = Body(lexer.pos)
    a_html.append_child(a_body)
    elems(lexer, a_body, [])
    if not lexer.is_a('EOF'):
        raise ParseError(lexer, 'EOF')        
    return a_html

class ParseError(Exception):
    def __init__(self, lexer, expected):
        Exception.__init__(self)        
        self.token = lexer.token
        self.line_number = lexer.cur_line_number
        self.column = lexer.cur_column
        self.pos = lexer.pos
        self.expected = expected
        
    def __str__(self):
        base = "Unexpected token %s at %s:%d" % (
            self.token.tag, self.line_number, self.column)
        if not self.expected:
            return base
        return base + ", expected one of " + str(self.expected)

LIST_TOKENS = {
    'BULLET': OrderedList,
}

BEAUTIFIER_TOKENS = {
    'ITAL': (Italicized, 'ITAL'), 
    'BOLD': (Bolded, 'BOLD'), 
    'UNDER': (Underlined, 'UNDER'), 
    'STRIKE': (Struckout, 'STRIKE'),
}

def add_elem(lexer, a_parent):
    if lexer.is_a('SPACE'):
        a_parent.append_text(lexer.pos, u' ')
        lexer.next()
    elif lexer.is_a('BLANK_LINE'):
        a_parent.append_child(Para(lexer.pos))
        lexer.next()
    elif lexer.is_a('HEADER'):
        a_parent.append_child(header(lexer))
    elif lexer.is_a('EMDASH'):
        a_parent.append_text(lexer.pos, unichr(8212))
        lexer.next()
    elif lexer.token.tag in LIST_TOKENS:
        a_parent.append_child(any_list(lexer))
    elif lexer.is_a('TABLE_ROW'):
        a_parent.append_child(table(lexer))
    elif lexer.is_a('L_SQUARE_SQUARE'):
        a_parent.append_child(link(lexer))
    elif lexer.is_a('L_SQUARE'):
        a_parent.append_child(image(lexer))
    elif lexer.is_a('INDENT'):
        a_parent.append_child(indented(lexer))
    elif lexer.is_a('TEXT') or lexer.is_a('SPACE'):
        a_parent.append_text(lexer.pos, lexer.token.u_text)
        lexer.next()
    elif lexer.is_a('L_CURLY'):
        a_parent.append_child(code(lexer))
    elif lexer.token.tag in BEAUTIFIER_TOKENS:
        a_parent.append_child(beautifier(lexer))
    elif lexer.is_a('INDENT'):
        a_parent.append_child(indented(lexer))
    else:
        return False
    return True

def elems(lexer, a_parent, stop_on_tags):
    while True:
        if lexer.token.tag in stop_on_tags:
            return a_parent
        
        if not add_elem(lexer, a_parent):
            return a_parent
            
def header(lexer):
    hlen = len(lexer.token.u_text) / 3
    a_hdr = Header(lexer.pos, hlen)
    u_text = lexer.skip_to_eol()
    u_text = u_text.strip()
    while u_text and u_text[-1] == '_': u_text = u_text[:-1]
    u_text = u_text.strip()
    a_hdr.append_text(lexer.pos, u_text)
    lexer.next()
    return a_hdr
            
def code(lexer):
    lexer.start_verbatim_mode()    
    lexer.next() # Consume the '{'
    
    # if followed by an indent, begins an indented code block:    
    # XXX Move this "unindenting white space" logic into lexer
    #     so that this code is less special.
    if lexer.is_a('SPACE'):
        u_ignored_space = lexer.token.u_text    
        lexer.next()
        if lexer.is_a('INDENT'):
            a_code = Code(lexer.pos)
            skip = u"\n" + (u" " * lexer.indent)
            indent_counter = 1
            lexer.next()
            while lexer.token.tag not in ['R_CURLY', 'EOF']:
                #if DEBUG: sys.stderr.write("Indent Counter: %d\n" % indent_counter)
                if lexer.is_a('INDENT'): 
                    indent_counter += 1
                    lexer.next()
                elif lexer.is_a('UNDENT'):                    
                    indent_counter -= 1
                    if indent_counter < 0: # Cannot unindent without exiting code mode:
                        raise ParseError(lexer, ['R_CURLY'])
                    lexer.next()
                elif lexer.token.tag in ['SPACE', 'BLANK_LINE']:
                    u_text = lexer.token.u_text.replace(skip, u"\n")
                    #if DEBUG: sys.stderr.write("Space: '%s'\n" % u_text)
                    a_code.append_text(lexer.pos, u_text)
                    lexer.next()
                else:
                    if not add_elem(lexer, a_code):
                        raise ParseError(lexer, [])
            
            lexer.require(['R_CURLY'])
            if indent_counter: # Indentation must have returned to where we started:
                raise ParseError(lexer, ['UNDENT'])            
            lexer.next()
            return a_code
    else:
        u_ignored_space = u""
            
    # otherwise, inline code block:    
    a_code = Monospaced(lexer.pos)
    if u_ignored_space:
        a_code.append_text(lexer.pos, u_ignored_space)
    elems(lexer, a_code, ['R_CURLY', 'BLANK_LINE'])
    lexer.require(['R_CURLY'])
    lexer.next()
    return a_code        
        
def beautifier(lexer):
    (ast_cls, end_tag) = BEAUTIFIER_TOKENS[lexer.token.tag]
    a_node = ast_cls(lexer.pos)
    lexer.next()
    elems(lexer, a_node, [end_tag, 'BLANK_LINE'])
    lexer.require([end_tag])
    lexer.next()    
    return a_node
    
def list_item(lexer):
    a_item = ListItem(lexer.pos)
    
    # Adjust intention level.  This way, if user writes:
    #   - A
    #     B
    #   - C
    #   D
    # then B is considered to be at the current indentation
    # level but lines C and D are not.
    new_indent = len(lexer.token.u_text) + 1
    lexer.push_indentation_level(new_indent)
    
    lexer.next()
    elems(lexer, a_item, ['UNDENT'])
    lexer.require(['UNDENT'])
    lexer.next()
    return a_item
    
def any_list(lexer):
    #sys.stderr.write("any_list(%s)\n" % lexer.token)
    list_tag = lexer.token.tag
    ast_cls = LIST_TOKENS[list_tag]
    a_list = ast_cls(lexer.pos)
    while lexer.token.tag == list_tag:
        a_item = list_item(lexer)
        a_list.append_child(a_item)
    return a_list
    
def elems_until_undent(lexer, a_parent):
    elems(lexer, a_parent, ())
    lexer.require(['UNDENT'])
    lexer.next()
    return a_parent

def indented(lexer):
    lexer.next() # consume INDENT
    if lexer.token.tag in LIST_TOKENS:
        # An indented list is just a list.
        a_result = any_list(lexer)
        lexer.require(['UNDENT'])
        lexer.next()
        return a_result
    else:
        a_result = Indented(lexer.pos)
        return elems_until_undent(lexer, a_result)

def table_row(lexer):
    a_row = TableRow(lexer.pos)
    
    while True:
        # Consume a CELL:
        a_cell = TableCell(lexer.pos)
        a_row.append_child(a_cell)
        lexer.next() 
        
        skip_space(lexer)
        
        # A cell followed by a newline and an indent
        # reads its content until the undent.  Otherwise,
        # we read until a blank line, row, or cell:
        if lexer.is_a('INDENT'):
            lexer.next()
            elems_until_undent(lexer, a_cell)
        else:
            elems(lexer, a_cell, ['TABLE_ROW', 'TABLE_CELL'])
        
        # If we found a cell separator, consume another CELL:
        if lexer.token.tag == 'TABLE_CELL': 
            continue       
            
        # Otherwise, we expect another ROW indicator to end the row:
        lexer.require('TABLE_ROW')
        lexer.next()
        return a_row
        
def table(lexer):
    a_table = Table(lexer.pos)
    
    while lexer.token.tag == 'TABLE_ROW':
        a_table.append_child(table_row(lexer))
        skip_space(lexer)
        
    return a_table
    
def skip_space(lexer):
    while lexer.token.tag == 'SPACE':
        lexer.next()

scheme = re.compile(ur"[a-zA-Z0-9+.-]+:")
def path_to_url(u_path):
    if scheme.match(u_path):
        i = u_path.index(u":")+1
    else:
        i = 0
    return u_path[:i].encode('ASCII') + urllib.quote(u_path[i:].encode('UTF-8'))
    
def url(lexer, a_node, term):
    # Only accept text and whitespace until ']':
    u_path = u""    
    
    skip_space(lexer)
    
    # XXX Rewrite to use verbatim_mode of lexer?
    VERB_TAGS = ['TEXT', 'SPACE'] + BEAUTIFIER_TOKENS.keys()
    
    while True:
        if lexer.token.tag in VERB_TAGS:
            u_path += lexer.token.u_text
            lexer.next()        
        elif lexer.token.tag == term:
            a_node.url = path_to_url(u_path)
            return
        else:
            raise ParseError(lexer, [term])
            
ext = re.compile(ur"\.[a-zA-Z0-9-]+$")
def default_text(url):
    u_text = urllib.unquote(url).decode("UTF-8")
    
    if not re.match(r"[a-zA-Z0-9+.-]+:", url):
        # Relative: strip extension if any
        mo = ext.search(u_text)
        if mo:
            u_text = u_text[:-len(mo.group(0))]
            
    return u_text
    
def link(lexer):
    # Saw [[
    a_link = Link(lexer.pos)
    lexer.next()
    elems(lexer, a_link, ['AT'])
    lexer.require('AT')
    a_link.rstrip_text()
    lexer.next()
    url(lexer, a_link, 'R_SQUARE_SQUARE')
    lexer.require(['R_SQUARE_SQUARE'])
    lexer.next()
    
    if not a_link.children_a:
        # Insert default text from URL.
        a_link.append_text(lexer.pos, default_text(a_link.url))
        
    return a_link
            
def image(lexer):
    # Saw '[':
    a_img = Image(lexer.pos)
    lexer.next()
    url(lexer, a_img, 'R_SQUARE')
    lexer.require(['R_SQUARE'])
    lexer.next()
    return a_img
    
# ___ Main _____________________________________________________________

def main(argv):
    dump = (argv and argv[0] == "-d")    
    try:
        ast = parse(sys.stdin)    
        if dump:
            ast.dump("", sys.stdout)
        else:
            ast.to_html(sys.stdout)
    except ParseError, e:
		print "<html><body>Error: %s</body></html>" % e
            
if __name__ == "__main__": 
    main(sys.argv[1:])