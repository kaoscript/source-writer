/**
 * writer.ks
 * Version 0.1.0
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
			_cache				= {
				array:			{}
				block:			{}
				comment:		{}
				control:		{}
				expression: 	{}
				indent:			{}
				line:			{}
				object:			{}
			}
			_fragments: Array	= []
			_indent: Number
			_options: Object
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
		constructor(options) { // {{{
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
		} // }}}
		comment(...args) { // {{{
			this.newComment(@indent).code(...args).done()

			return this
		} // }}}
		insertAt(index, ...args) { // {{{
			const l = @fragments.length

			@fragments.splice(index, 0, ...args)

			return @fragments.length - l
		} // }}}
		line(...args) { // {{{
			this.newLine(@indent).code(...args).done()

			return this
		} // }}}
		mark() => new this.Mark(this, @indent, @fragments.length)
		newArray(indent = @indent) { // {{{
			@cache.array[indent] ??= new this.Array(this, indent)

			return @cache.array[indent].init()
		} // }}}
		newBlock(indent = @indent, breakable = false) { // {{{
			const key = `\(indent)|\(breakable)`

			@cache.block[key] ??= new this.Block(this, indent, breakable)

			return @cache.block[key].init()
		} // }}}
		newComment(indent = @indent) { // {{{
			@cache.comment[indent] ??= new this.Comment(this, indent)

			return @cache.comment[indent].init()
		} // }}}
		newControl(indent = @indent, breakable = true) { // {{{
			const key = `\(indent)|\(breakable)`

			@cache.control[key] ??= new this.Control(this, indent, breakable)

			return @cache.control[key].init()
		} // }}}
		newExpression(indent = @indent) { // {{{
			@cache.expression[indent] ??= new this.Expression(this, indent)

			return @cache.expression[indent].init()
		} // }}}
		newFragment(...args) { // {{{
			return new this.Fragment(...args)
		} // }}}
		newIndent(indent) { // {{{
			return @cache.indent[indent] ?? (@cache.indent[indent] = new this.Fragment('\t'.repeat(indent)))
		} // }}}
		newLine(indent = @indent) { // {{{
			@cache.line[indent] ??= new this.Line(this, indent)

			return @cache.line[indent].init()
		} // }}}
		newObject(indent = @indent) { // {{{
			@cache.object[indent] ??= new this.Object(this, indent)

			return @cache.object[indent].init()
		} // }}}
		push(...args) { // {{{
			@fragments.push(...args)

			return this
		} // }}}
		toArray() => @fragments
	}

	class Fragment {
		public {
			code
		}
		constructor(@code)
		toString() { // {{{
			return @code
		} // }}}
	}

	class ArrayWriter {
		private {
			_indent: Number
			_line				= null
			_writer
		}
		constructor(@writer, @indent)
		done() { // {{{
			if @line != null {
				@line.done()

				@line = null

				@writer.push(@writer.newFragment('\n'), @writer.newIndent(@indent), @writer.newFragment(']'))
			}
			else {
				@writer.push(@writer.newFragment(']'))
			}
		} // }}}
		private init() { // {{{
			@line = null

			@writer.push(@writer.newFragment('['))

			return this
		} // }}}
		line(...args) { // {{{
			this.newLine().code(...args)

			return this
		} // }}}
		newControl() { // {{{
			if @line != null {
				@line.done()

				@writer.push(@writer.newFragment(',\n'))
			}
			else {
				@writer.push(@writer.newFragment('\n'))
			}

			return @line = @writer.newControl(@indent + 1, false)
		} // }}}
		newLine() { // {{{
			if @line != null {
				@line.done()

				@writer.push(@writer.newFragment(@writer.listTerminator))
			}
			else {
				@writer.push(@writer.newFragment('\n'))
			}

			return @line = @writer.newExpression(@indent + 1)
		} // }}}
	}

	class BlockWriter {
		private {
			_breakable: Boolean
			_indent: Number
			_undone: Boolean		= true
			_writer
		}
		constructor(@writer, @indent, @breakable = false)
		done() { // {{{
			if @undone {
				@writer.push(@writer.newIndent(@indent), @writer.newFragment('}'))

				if @breakable {
					@writer.push(@writer.breakTerminator)
				}

				@undone = false

				return true
			}
			else {
				return false
			}
		} // }}}
		private init() { // {{{
			if @breakable {
				@writer.push(@writer.newIndent(@indent), @writer.newFragment('{\n'))
			}
			else {
				@writer.push(@writer.newFragment(' {\n'))
			}

			@undone = true

			return this
		} // }}}
		line(...args) { // {{{
			@writer.newLine(@indent + 1).code(...args).done()

			return this
		} // }}}
		newBlock(indent = @indent + 1) { // {{{
			return @writer.newBlock(indent, true)
		} // }}}
		newControl(indent = @indent + 1) { // {{{
			return @writer.newControl(indent)
		} // }}}
		newLine(indent = @indent + 1) { // {{{
			return @writer.newLine(indent)
		} // }}}
	}

	class ControlWriter {
		private {
			_breakable: Boolean
			_firstStep: Boolean			= true
			_indent: Number
			_step
			_writer
		}
		constructor(@writer, @indent, @breakable = true)
		code(...args) { // {{{
			@step.code(...args)

			return this
		} // }}}
		done() { // {{{
			if @step.done() && @breakable {
				@writer.push(@writer.breakTerminator)
			}
		} // }}}
		isFirstStep() => @firstStep
		private init() { // {{{
			@step = @writer.newExpression(@indent)

			@firstStep = true

			return this
		} // }}}
		line(...args) { // {{{
			@step.line(...args)

			return this
		} // }}}
		newControl() { // {{{
			return @step.newControl()
		} // }}}
		newLine() { // {{{
			return @step.newLine()
		} // }}}
		step() { // {{{
			@step.done()

			if @step is ExpressionWriter {
				@step = @writer.newBlock(@indent)
			}
			else {
				if @breakable {
					@writer.push(@writer.newFragment('\n'))
				}

				@step = @writer.newExpression(@indent)
			}

			if @firstStep {
				@firstStep = false
			}

			return this
		} // }}}
	}

	class ExpressionWriter {
		private {
			_indent: Number
			_undone: Boolean	= true
			_writer
		}
		constructor(@writer, @indent)
		code(...args) { // {{{
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

			return this
		} // }}}
		done() { // {{{
			if @undone {
				@undone = false

				return true
			}
			else {
				return false
			}
		} // }}}
		private init() { // {{{
			@writer.push(@writer.newIndent(@indent))

			@undone = true

			return this
		} // }}}
		newArray(indent = @indent) { // {{{
			return @writer.newArray(indent)
		} // }}}
		newBlock(indent = @indent) { // {{{
			return @writer.newBlock(indent)
		} // }}}
		newControl(indent = @indent + 1) { // {{{
			return @writer.newControl(indent)
		} // }}}
		newLine(indent = @indent + 1) { // {{{
			return @writer.newLine(indent)
		} // }}}
		newObject(indent = @indent) { // {{{
			return @writer.newObject(indent)
		} // }}}
	}

	class CommentWriter extends ExpressionWriter {
		done() { // {{{
			if @undone {
				@writer.push(@writer.breakTerminator)

				@undone = false
			}
		} // }}}
		newLine() => this
	}

	class LineWriter extends ExpressionWriter {
		done() { // {{{
			if @undone {
				@writer.push(@writer.lineTerminator)

				@undone = false
			}
		} // }}}
		newLine() => this
	}

	class ObjectWriter {
		private {
			_indent: Number
			_line				= null
			_writer
		}
		constructor(@writer, @indent)
		done() { // {{{
			if @line != null {
				@line.done()

				@line = null

				@writer.push(@writer.newFragment('\n'), @writer.newIndent(@indent), @writer.newFragment('}'))
			}
			else {
				@writer.push(@writer.newFragment('}'))
			}
		} // }}}
		private init() { // {{{
			@line = null

			@writer.push(@writer.newFragment('{'))

			return this
		} // }}}
		line(...args) { // {{{
			this.newLine().code(...args)

			return this
		} // }}}
		newControl() { // {{{
			if @line != null {
				@line.done()

				@writer.push(@writer.newFragment(@writer.listTerminator))
			}
			else {
				@writer.push(@writer.newFragment('\n'))
			}

			return @line = @writer.newControl(@indent + 1, false)
		} // }}}
		newLine() { // {{{
			if @line != null {
				@line.done()

				@writer.push(@writer.newFragment(@writer.listTerminator))
			}
			else {
				@writer.push(@writer.newFragment('\n'))
			}

			return @line = @writer.newExpression(@indent + 1)
		} // }}}
	}

	class MarkWriter {
		private {
			_indent: Number
			_index: Number
			_writer
		}
		public {
			breakTerminator: Fragment
			lineTerminator: Fragment
			listTerminator: Fragment
		}
		constructor(@writer, @indent, @index) { // {{{
			@breakTerminator = @writer.breakTerminator
			@lineTerminator = @writer.lineTerminator
			@listTerminator = @writer.listTerminator
		} // }}}
		line(...args) { // {{{
			this.newLine().code(...args).done()

			return this
		} // }}}
		newControl() => new this._writer.Control(this, @indent)
		newFragment(...args) => @writer.newFragment(...args)
		newLine() => new this._writer.Line(this, @indent)
		push(...args) { // {{{
			@index += @writer.insertAt(@index, ...args)

			return this
		} // }}}
	}
}