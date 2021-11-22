extends EBBCodeParser
class_name MarkdownParser

# Markdown Parser
# With support for <values> and :emojis:
# For emojis you need to install emojis-for-godot

func parse(text:String, editor:=false, headers_fonts :=[], variables:={}) -> String:
	# run base.parse
	text = convert_markdown(text)
	text = .parse(text, editor, headers_fonts, variables)
	return text

func convert_markdown(text:String) -> String:
	var re = RegEx.new()
	var output = "" + text
	var replacement = ""
	
	# ![](path/to/img)
	re.compile("!\u200B?\\[\u200B?\\]\\(([^\\(\\)\\[\\]]+)\\)")
	for result in re.search_all(text):
		if result.get_string():
			replacement = "[img]%s[/img]" % result.get_string(1)
			output = regex_replace(result, output, replacement)
	text = output

	# either plain "prot://url" and "[link](url)" and not "[img]url[\img]"
	re.compile("(\\[img\\][^\\[\\]]*\\[\\/img\\])|(?:(?:\\[([^\\]\\)]+)\\]\\((\\w+:\\/\\/[^\\)]+)\\))|(\\w+:\\/\\/[^ \\[\\]]*[\\w\\d_]+))")
	for result in re.search_all(text):
		# having anything in 1 meant it matched "[img]url[\img]"
		if result.get_string() and not result.get_string(1): 
			if result.get_string(4):
				replacement = "[url]%s[/url]" % result.get_string(4)
			else:
				# That can can be the user erroneously writing "[b](url)[\b]" need to be pointed in the doc
				replacement = "[url=%s]%s[/url]" % [result.get_string(3), result.get_string(2)]
			output = regex_replace(result, output, replacement)
	text = output

	# **bold**
	re.compile("\\*\\*([^\\*]+)\\*\\*")
	for result in re.search_all(text):
		if result.get_string():
			replacement = "[b]%s[/b]" % result.get_string(1)
			output = regex_replace(result, output, replacement)
	text = output

	# *italic*
	re.compile("\\*([^\\*]+)\\*")
	for result in re.search_all(text):
		if result.get_string():
			replacement = "[i]%s[/i]" % result.get_string(1)
			output = regex_replace(result, output, replacement)
	text = output

	# ~~strike through~~
	re.compile("~~([^~]+)~~")
	for result in re.search_all(text):
		if result.get_string():
			replacement = "[s]%s[/s]" % result.get_string(1)
			output = regex_replace(result, output, replacement)
	text = output

	# `code`
	re.compile("`([^`]+)`")
	for result in re.search_all(text):
		if result.get_string():
			replacement = "[code]%s[/code]" % result.get_string(1)
			output = regex_replace(result, output, replacement)
	text = output

	# @tabel=2 {
	# | cell1 | cell2 |
	# }
	re.compile("@table=([0-9]+)\\s*\\{\\s*((\\|.+)\n)+\\}")
	for result in re.search_all(text):
		if result.get_string():
			replacement = "[table=%s]" % result.get_string(1)
			# cell 1 | cell 2
			var r = result.get_string()
			var lines = r.split("\n")
			for line in lines:
				if line.begins_with("|"):
					var cells : Array = line.split("|", false)
					for cell in cells:
						replacement += "[cell]%s[/cell]" % cell
					replacement += "\n"
			replacement += "[/table]"
			output = regex_replace(result, output, replacement)
	text = output

	# todo:
	# @color=red{red text}
	# @color=#c39f00{custom colored text}

	# @center { text }
	output = parse_keyword(text, "center", "center")
	text = output

	# @u { text}
	output = parse_keyword(text, "u", "u")
	text = output

	# @right { text }
	output = parse_keyword(text, "right", "right")
	text = output

	# @fill { text }
	output = parse_keyword(text, "fill", "fill")
	text = output

	# @justified { text }
	output = parse_keyword(text, "justified", "fill")
	text = output

	# @indent { text }
	output = parse_keyword(text, "indent", "indent")
	text = output

	# @tab { text }
	output = parse_keyword(text, "tab", "indent")
	text = output

	# @wave amp=50 freq=2{ text }
	output = parse_effect(text, "wave", "amp", "freq")
	text = output

	# @tornado radius=5 freq=2{ text }
	output = parse_effect(text, "tornado", "radius", "freq")
	text = output

	# @shake rate=5 level=10{ text }
	output = parse_effect(text, "shake", "rate", "level")
	text = output

	# @fade start=4 length=14{ text }
	output = parse_effect(text, "fade", "start", "length")
	text = output

	# todo:
	# @rainbow freq=0.2 sat=10 val=20{ text }




	return output

func parse_effect(text:String, effect:String, arg1:String, arg2:String) -> String:
	var re = RegEx.new()
	var output = "" + text
	var replacement = ""
	
	# @effect arg1=0 arg2=0 { text }
	re.compile("@%s\\s%s=(\\d+)\\s%s=(\\d+)\\s*{(.+)}" % [effect, arg1, arg2])
	for result in re.search_all(text):
		if result.get_string():
			var val1 = result.get_string(1)
			var val2 = result.get_string(2)
			var _text = result.get_string(3)
			replacement = "[%s %s=%s %s=%s]%s[/%s]"
			replacement = replacement % [effect, arg1, val1, arg2, val2, _text, effect]
			output = regex_replace(result, output, replacement)
	
	return output


	

func parse_keyword(text:String, keyword:String, tag:String) -> String:
	var re = RegEx.new()
	var output = "" + text
	var replacement = ""

	# @keyword {text}
	re.compile("@%s\\s*{(.+)}" % keyword)
	for result in re.search_all(text):
		if result.get_string():
			replacement = "[%s]%s[/%s]" % [tag, result.get_string(1), tag]
			output = regex_replace(result, output, replacement)

	return output

func parse_headers(text:String, headers_fonts:=[]) -> String:
	var headers_count = headers_fonts.size()

	if headers_count == 0:
		return text

	var re = RegEx.new()
	var output = "" + text

	re.compile("(#+)\\s+(.+)\n")
	for result in re.search_all(text):
		if result.get_string():
			var header_level = headers_count - result.get_string(1).length()
			header_level = clamp(header_level, 0, headers_count)
			var header_text = result.get_string(2)
			var header_font = headers_fonts[header_level]
			var replacement = "[font=%s]%s[/font]\n" % [header_font, header_text]
			output = regex_replace(result, output, replacement)
	
	return output
