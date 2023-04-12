/**
 * writer.ks
 * Version 0.2.0
 * August 3rd, 2017
 *
 * Copyright (c) 2017 Baptiste Augrain
 * Licensed under the MIT license.
 * http://www.opensource.org/licenses/mit-license.php
 **/
include '@kaoscript/util'

export {
	class Writer {
		private {
			@cache					= {
				array:				{}
				block:				{}
				comment:			{}
				control:			{}
				expression: 		{}
				indent:				{}
				line:				{}
				object:				{}
			}
			@fragments: Fragment[]	= []
			@indent: Number
			@options: Object
		}
		public {
			Array: class
			Block: class
			Comment: class
			Control: class
			Expression: class
			Fragment: class
			Line: class
			Mark: class
			Object: class

			breakTerminator: Fragment
			lineTerminator: Fragment
			listTerminator: Fragment
		}
		constructor(options = {}) { # {{{
			@options = Object.merge({
				indent: {
					level: 0
					style: 'tab'
					size: 4
				}
				terminators: {
					line: ';'
					list: ','
				}
				classes: {
					array: ArrayWriter
					block: BlockWriter
					comment: CommentWriter
					control: ControlWriter
					expression: ExpressionWriter
					fragment: Fragment
					line: LineWriter
					mark: MarkWriter
					object: ObjectWriter
				}
			}, options)

			@indent = @options.indent.level

			@Array = @options.classes.array
			@Block = @options.classes.block
			@Comment = @options.classes.comment
			@Control = @options.classes.control
			@Expression = @options.classes.expression
			@Fragment = @options.classes.fragment
			@Line = @options.classes.line
			@Mark = @options.classes.mark
			@Object = @options.classes.object

			@breakTerminator = this.newFragment(`\n`)
			@lineTerminator = this.newFragment(`\(@options.terminators.line)\n`)
			@listTerminator = this.newFragment(`\(@options.terminators.list)\n`)
		} # }}}
		comment(...args): this { # {{{
			this.newComment(@indent).code(...args).done()
		} # }}}
		insertAt(index, ...args): Number { # {{{
			var l = @fragments.length

			@fragments.splice(index, 0, ...args)

			return @fragments.length - l
		} # }}}
		length(): Number => @fragments.length
		line(...args): this { # {{{
			this.newLine(@indent).code(...args).done()
		} # }}}
		mark(indent = @indent) => this.Mark.new(this, indent, @fragments.length)
		newArray(indent = @indent) { # {{{
			@cache.array[indent] ??= this.Array.new(this, indent)

			return @cache.array[indent].init()
		} # }}}
		newBlock(indent = @indent, breakable = false) { # {{{
			var key = `\(indent)|\(breakable)`

			@cache.block[key] ??= this.Block.new(this, indent, breakable)

			return @cache.block[key].init()
		} # }}}
		newComment(indent = @indent) { # {{{
			@cache.comment[indent] ??= this.Comment.new(this, indent)

			return @cache.comment[indent].init()
		} # }}}
		newControl(indent = @indent, initiator = true, separator = true, terminator = true) { # {{{
			var key = `\(indent)|\(initiator)|\(separator)|\(terminator)`

			@cache.control[key] ??= this.Control.new(this, indent, initiator, separator, terminator)

			return @cache.control[key].init()
		} # }}}
		newExpression(indent = @indent, initiator = true, terminator = true) { # {{{
			var key = `\(indent)|\(initiator)|\(terminator)`

			@cache.expression[key] ??= this.Expression.new(this, indent, initiator, terminator)

			return @cache.expression[key].init()
		} # }}}
		newFragment(...args) { # {{{
			return this.Fragment.new(...args)
		} # }}}
		newIndent(indent) { # {{{
			return @cache.indent[indent] ?? (@cache.indent[indent] <- this.Fragment.new('\t'.repeat(indent)))
		} # }}}
		newLine(indent = @indent, initiator = true, terminator = true) { # {{{
			var key = `\(indent)|\(initiator)|\(terminator)`

			@cache.line[key] ??= this.Line.new(this, indent, initiator, terminator)

			return @cache.line[key].init()
		} # }}}
		newObject(indent = @indent) { # {{{
			@cache.object[indent] ??= this.Object.new(this, indent)

			return @cache.object[indent].init()
		} # }}}
		push(...args): this { # {{{
			@fragments.push(...args)
		} # }}}
		toArray(): Fragment[] => @fragments
	}

	class Fragment {
		public {
			code: String
		}
		constructor(@code)
		constructor(code: Boolean | Number) { # {{{
			@code = `\(code)`
		} # }}}
		toString(): String { # {{{
			return @code
		} # }}}
	}

	class ArrayWriter {
		private {
			@indent: Number
			@line				= null
			@writer
		}
		constructor(@writer, @indent)
		done(): Void { # {{{
			if ?@line {
				@line.done()

				@line = null

				@writer.push(@writer.newFragment('\n'), @writer.newIndent(@indent), @writer.newFragment(']'))
			}
			else {
				@writer.push(@writer.newFragment(']'))
			}
		} # }}}
		private init(): this { # {{{
			@line = null

			@writer.push(@writer.newFragment('['))
		} # }}}
		line(...args): this { # {{{
			this.newLine().code(...args)
		} # }}}
		newControl() { # {{{
			if @line != null {
				@line.done()

				@writer.push(@writer.newFragment(',\n'))
			}
			else {
				@writer.push(@writer.newFragment('\n'))
			}

			return @line <- @writer.newControl(@indent + 1, false)
		} # }}}
		newLine() { # {{{
			if @line != null {
				@line.done()

				@writer.push(@writer.listTerminator)
			}
			else {
				@writer.push(@writer.newFragment('\n'))
			}

			return @line <- @writer.newExpression(@indent + 1)
		} # }}}
	}

	class BlockWriter {
		private {
			@breakable: Boolean
			@indent: Number
			@notDone: Boolean		= true
			@writer
		}
		constructor(@writer, @indent, @breakable = false)
		done() { # {{{
			if @notDone {
				@writer.push(@writer.newIndent(@indent), @writer.newFragment('}'))

				if @breakable {
					@writer.push(@writer.breakTerminator)
				}

				@notDone = false

				return true
			}
			else {
				return false
			}
		} # }}}
		private init(): this { # {{{
			if @breakable {
				@writer.push(@writer.newIndent(@indent), @writer.newFragment('{\n'))
			}
			else {
				@writer.push(@writer.newFragment(' {\n'))
			}

			@notDone = true
		} # }}}
		length() => @writer.length()
		line(...args): this { # {{{
			@writer.newLine(@indent + 1).code(...args).done()
		} # }}}
		mark(indent = @indent + 1) => @writer.mark(indent)
		newBlock(indent = @indent + 1) { # {{{
			return @writer.newBlock(indent, true)
		} # }}}
		newControl(indent = @indent + 1, initiator = true, separator = true, terminator = true) { # {{{
			return @writer.newControl(indent, initiator, separator, terminator)
		} # }}}
		newLine(indent = @indent + 1, initiator = true, terminator = true) { # {{{
			return @writer.newLine(indent, initiator, terminator)
		} # }}}
	}

	class ControlWriter {
		private {
			@firstStep: Boolean			= true
			@indent: Number
			@initiator: Boolean
			@separator: Boolean
			@step
			@terminator: Boolean
			@writer
		}
		constructor(@writer, @indent, @initiator = true, @separator = true, @terminator = true)
		code(...args): this { # {{{
			@step.code(...args)
		} # }}}
		done() { # {{{
			if @step.done() && @terminator {
				@writer.push(@writer.breakTerminator)
			}
		} # }}}
		isFirstStep() => @firstStep
		private init(): this { # {{{
			@step = @writer.newExpression(@indent, @initiator)

			@firstStep = true
		} # }}}
		line(...args): this { # {{{
			@step.line(...args)
		} # }}}
		newControl() { # {{{
			return @step.newControl()
		} # }}}
		newLine() { # {{{
			return @step.newLine()
		} # }}}
		step(): this { # {{{
			@step.done()

			if @step is ExpressionWriter {
				@step = @writer.newBlock(@indent)
			}
			else {
				if @separator {
					@writer.push(@writer.newFragment('\n'))
				}

				@step = @writer.newExpression(@indent)
			}

			if @firstStep {
				@firstStep = false
			}
		} # }}}
	}

	class ExpressionWriter {
		private {
			@indent: Number
			@initiator: Boolean
			@terminator: Boolean
			@notDone: Boolean	= true
			@writer
		}
		constructor(@writer, @indent, @initiator = true, @terminator = true)
		code(...args): this { # {{{
			for arg in args {
				if arg is Array {
					this.code(...arg)
				}
				else if arg is Object {
					@writer.push(arg)
				}
				else {
					@writer.push(@writer.newFragment(arg))
				}
			}
		} # }}}
		done() { # {{{
			if @notDone {
				@notDone = false

				return true
			}
			else {
				return false
			}
		} # }}}
		private init(): this { # {{{
			if @initiator {
				@writer.push(@writer.newIndent(@indent))
			}

			@notDone = true
		} # }}}
		newArray(indent = @indent) { # {{{
			return @writer.newArray(indent)
		} # }}}
		newBlock(indent = @indent) { # {{{
			return @writer.newBlock(indent)
		} # }}}
		newControl(indent = @indent + 1, initiator = true, separator = true, terminator = true) { # {{{
			return @writer.newControl(indent, initiator, separator, terminator)
		} # }}}
		newIndent(indent = @indent + 1): this { # {{{
			@writer.push(@writer.newIndent(indent))
		} # }}}
		newLine(indent = @indent + 1) { # {{{
			return @writer.newLine(indent)
		} # }}}
		newObject(indent = @indent) { # {{{
			return @writer.newObject(indent)
		} # }}}
	}

	class CommentWriter extends ExpressionWriter {
		done() { # {{{
			if @notDone {
				@writer.push(@writer.breakTerminator)

				@notDone = false
			}
		} # }}}
		newLine() => this
	}

	class LineWriter extends ExpressionWriter {
		done() { # {{{
			if @notDone {
				if @terminator {
					@writer.push(@writer.lineTerminator)
				}

				@notDone = false
			}
		} # }}}
		newControl(indent = @indent, initiator = true, separator = true, terminator = true) { # {{{
			return @writer.newControl(indent, initiator, separator, terminator)
		} # }}}
		newLine() => this
	}

	class ObjectWriter {
		private {
			@indent: Number
			@line				= null
			@writer
		}
		constructor(@writer, @indent)
		done() { # {{{
			if @line != null {
				@line.done()

				@line = null

				@writer.push(@writer.newFragment('\n'), @writer.newIndent(@indent), @writer.newFragment('}'))
			}
			else {
				@writer.push(@writer.newFragment('}'))
			}
		} # }}}
		private init(): this { # {{{
			@line = null

			@writer.push(@writer.newFragment('{'))
		} # }}}
		line(...args): this { # {{{
			this.newLine().code(...args)
		} # }}}
		newControl() { # {{{
			if @line != null {
				@line.done()

				@writer.push(@writer.listTerminator)
			}
			else {
				@writer.push(@writer.newFragment('\n'))
			}

			return @line <- @writer.newControl(@indent + 1, true, true, false)
		} # }}}
		newLine() { # {{{
			if @line != null {
				@line.done()

				@writer.push(@writer.listTerminator)
			}
			else {
				@writer.push(@writer.newFragment('\n'))
			}

			return @line <- @writer.newExpression(@indent + 1)
		} # }}}
	}

	class MarkWriter {
		private {
			@delta: Number		= 0
			@indent: Number
			@index: Number		= -1
			@mark: MarkWriter?	= null
			@relative: Boolean	= false
			@writer
		}
		public {
			breakTerminator: Fragment
			lineTerminator: Fragment
			listTerminator: Fragment
		}
		private constructor(@writer, @indent) { # {{{
			@breakTerminator = @writer.breakTerminator
			@lineTerminator = @writer.lineTerminator
			@listTerminator = @writer.listTerminator
		} # }}}
		constructor(@writer, @indent, @index) { # {{{
			this(writer, indent)
		} # }}}
		constructor(@mark) { # {{{
			this(mark._writer, mark._indent)

			@relative = true
		} # }}}
		index() { # {{{
			if @relative {
				return @mark!?.index() + @delta
			}
			else {
				return @index
			}
		} # }}}
		line(...args): this { # {{{
			this.newLine().code(...args).done()
		} # }}}
		mark() => MarkWriter.new(this)
		newControl() => @writer.Control.new(this, @indent).init()
		newFragment(...args) => @writer.newFragment(...args)
		newIndent(indent) => @writer.newIndent(indent)
		newLine() => @writer.Line.new(this, @indent).init()
		push(...args): this { # {{{
			if @relative {
				@delta += @writer.insertAt(this.index(), ...args)
			}
			else {
				@index += @writer.insertAt(@index, ...args)
			}
		} # }}}
	}
}
