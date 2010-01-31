#!/usr/bin/env python

# Spanakopita markup tool.  The markup is loosely based on http://txt2tags.sf.net.
# See markup.sp for an explanation.

import sys, re

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
            
class Html(ParentAst):
    html = "html"

class Body(ParentAst):
    html = "body"

class Text(LeafAst):
    def __init__(self, pos, u_text):
        super(Text, self).__init__(pos)
        self.u_text = u_text        
        
    def to_html(self, out):
        # XXX Escape entities.
        out.write(self.u_text.encode("utf-8"))
        
    def __str__(self):
        return "%s(text=%s)" % (self.tag, self.u_text)
    
class Para(LeafAst):
    def to_html(self, out):
        out.write("<p>")
            
class Indented(ParentAst):    
    html = "blockquote"

class Code(ParentAst):
    html = "pre"

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
            
class UnorderedList(List):
    html = "ul"
    
class OrderedList(List):
    html = "ol"

class Table(ParentAst):
    # Children: table rows.
    html = "table"
    
class TableRow(ParentAst):
    # Children: table columns.
    html = "tr"
    
class TableCell(ParentAst):    
    # Children: misc elems.
    html = "td"

class VerbatimText(LeafAst):
    def __init__(self, pos, u_text):
        super(VerbatimText, self).__init__(pos)
        self.u_text = u_text
        
    def to_html(self, out):
        out.write('<pre>' % self.u_text.encode("UTF-8"))
                
    def __str__(self):
        return "%s(text=%s)" % (self.tag, self.u_text)
    
class Image(LeafAst):
    def __init__(self, pos, url):
        super(Image, self).__init__(pos)
        self.url = url
        
    def to_html(self, out):
        out.write('<img src="%s">' % url)
                
    def __str__(self):
        return "%s(url=%s)".format(self.tag, self.url)
        
class Link(ParentAst):
    def __init__(self, pos, url):
        super(Link, self).__init__(pos)
        self.url = url

    def to_html(self, out):
        out.write('<a href="%s">' % url)
        for c in self.children_a: c.to_html(out)
        out.write('</a>')

    def __str__(self):
        return "%s(url=%s)".format(self.tag, self.url)

# ___ Lexer ____________________________________________________________
#
# Newlines and whitespace are handled as follows: 
#
#   Ignorable whitespace generates the token SPACE.  This includes a single newline
#   which does not change the indentation level.
#
#   Two or more consecutive newlines generates the token BLANK_LINE.
#
#   In addition, whenever a newline is followed by a new level of indentation,
#   one or mode INDENT and UNDENT tokens are produced.
    
# Applied within lines:
WITHIN_REGULAR_EXPRESSIONS = {
    'ITAL': re.compile(r'//'),
    'BOLD': re.compile(r'\*\*'),
    'UNDER': re.compile(r'__'),
    'STRIKE': re.compile(r'--'),
    
    'TABLE_ROW': re.compile(r'\|\|'),
    'TABLE_CELL': re.compile(r'\|'),
    
    'L_CURLY': re.compile(r'{'),
    'R_CURLY': re.compile(r'}'),
    
    'L_SQUARE': re.compile(r'\['),
    'R_SQUARE': re.compile(r'\]'),
}

# Checked only at the start of a line:
START_REGULAR_EXPRESSIONS = {
    'HEADER': re.compile(r'___'),
    'BULLET': re.compile(r'-'),
    'HASH': re.compile(r'\#')
}

class Token(object):
    def __init__(self, tag, u_text):
        self.tag = tag
        self.u_text = u_text
        
    def __str__(self):
        return "%s(%s)" % (self.tag, self.u_text)
        
class Lexer(object):
    
    def __init__(self, u_text):
        self.u_text = u_text
        self.eol = True
        self.pos = 0
        self.indent = 0 # Indent of current line.
        self.indents = [0] # Indents for which we have issued tokens.
        self.token = None
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
        return not (c.isspace() or c in u"*/\\{}[]|\n")
        
    def next(self):
        self._next()        
        sys.stderr.write("%s\n" % (self.token,))
        return self.token
        
    def push_indentation_level(self, rel_amnt):
        """
        Pushes an indentation level to rel_amnt more than it is now.  
        When the indentation drops lower, an UNDENT token will be generated.
        Used for bullet lists.
        """
        self.indent += rel_amnt
        self.indents.append(self.indent)
        
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
        
        # Check for characters only significant at the start of the line:
        if self.eol:
            for (tag, regexp) in START_REGULAR_EXPRESSIONS.items():
                if self.check_regexp(tag, regexp):
                    return
            self.eol = False
                    
        # Check for all special characters:
        for (tag, regexp) in WITHIN_REGULAR_EXPRESSIONS.items():
            if self.check_regexp(tag, regexp):
                return 
                
        # Just accumulate one word of text:
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
    'BULLET': UnorderedList,
    'HASH': OrderedList
}

BEAUTIFIER_TOKENS = {
    'ITAL': (Italicized, 'ITAL'), 
    'BOLD': (Bolded, 'BOLD'), 
    'UNDER': (Underlined, 'UNDER'), 
    'STRIKE': (Struckout, 'STRIKE'),
}

def elems(lexer, a_parent, stop_on_tags):
    while True:
        if lexer.token.tag in stop_on_tags:
            return a_parent
            
        if lexer.is_a('SPACE'):
            a_parent.append_text(lexer.pos, u' ')
            lexer.next()
            continue
            
        if lexer.is_a('BLANK_LINE'):
            a_parent.append_child(Para(lexer.pos))
            lexer.next()
            continue
            
        if lexer.token.tag in LIST_TOKENS:
            a_parent.append_child(any_list(lexer))
            continue

        if lexer.is_a('TABLE_START'):
            a_parent.append_child(table(lexer))
            continue
        
        if lexer.is_a('INDENT'):
            a_parent.append_child(indented(lexer))
            continue

        if lexer.is_a('TEXT') or lexer.is_a('SPACE'):
            a_parent.append_text(lexer.pos, lexer.token.u_text)
            lexer.next()
            continue
            
        if lexer.is_a('L_CURLY'):
            a_parent.append_child(code(lexer))
            continue

        if lexer.token.tag in BEAUTIFIER_TOKENS:
            a_parent.append_child(beautifier(lexer))
            lexer.next()
            continue

        if lexer.is_a('INDENT'):
            a_parent.append_child(indented(lexer))
            continue

        return a_parent
        
def code(lexer):
    lexer.next()
    
    u_ignored_space = u""
    if lexer.is_a('SPACE'):
        u_ignored_space = lexer.token.u_text
        skip = u"\n" + (u" " * lexer.indent)
        lexer.next()
        if lexer.is_a('INDENT'):
            a_code = Code(lexer.pos)
            
            indent_counter = 1
            while indent_counter:
                lexer.next()
                if lexer.is_a('INDENT'): 
                    indent_counter += 1
                elif lexer.is_a('UNDENT'):                    
                    indent_counter -= 1
                elif lexer.token.tag in ['SPACE', 'BLANK_LINE']:
                    u_text = lexer.token.u_text.replace(skip, u"\n")
                    a_code.append_text(lexer.pos, u_text)
                else:
                    a_code.append_text(lexer.pos, lexer.token.u_text)
            
            # Append the final whitespace up until the last newline:
            (u_ws, u_sep, _) = lexer.token.u_text.rpartition(u"\n")
            a_code.append_text(lexer.pos, u_ws)
            a_code.append_text(lexer.pos, u_sep)
            
            lexer.next()
            lexer.require(['R_CURLY'])
            lexer.next()
            return a_code
    
    a_code = Monospaced(lexer.pos)
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
    sys.stderr.write("any_list(%s)\n" % lexer.token)
    list_tag = lexer.token.tag
    ast_cls = LIST_TOKENS[list_tag]
    a_list = ast_cls(lexer.pos)
    while lexer.token.tag == list_tag:
        a_item = list_item(lexer)
        a_list.append_child(a_item)
    return a_list

def indented(lexer):
    lexer.next()
    if lexer.token.tag in LIST_TOKENS:
        a_result = any_list(lexer)
    else:
        a_result = Indented(lexer.pos)
        elems(lexer, a_indented, ())
    lexer.require(['UNDENT'])
    lexer.next()
    return a_result

def table_row(lexer):
    a_row = TableRow(lexer.pos)
    
    while True:
        # Consume a CELL:
        a_cell = TableCell(lexer.pos)
        lexer.next() 
        elems(lexer, a_cell)
        a_row.append_child(a_cell)
        
        # If we found a separator, consume another CELL:
        if lexer.token.tag == 'TABLE_CELL': 
            continue            
        return a_row
        
def table(lexer):
    a_table = Table(lexer.pos)
    
    while lexer.token.tag == 'TABLE_ROW':
        a_table.append_child(table_row(lexer))
        
    return a_table
    
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
        print e
            
if __name__ == "__main__": 
    main(sys.argv[1:])