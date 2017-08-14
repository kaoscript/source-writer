/**
 * writer.ks
 * Version 0.1.0
 * August 3rd, 2017
 *
 * Copyright (c) 2017 Baptiste Augrain
 * Licensed under the MIT license.
 * http://www.opensource.org/licenses/mit-license.php
 **/
include once '@kaoscript/util'

export {
	class Writer {
		private {
			_cache				= {
				array:			{}
				block:			{}
				expression: 	{}
				indent:			{}
				line:			{}
				object:			{}
			}
			_fragments: Array	= []
			_indent: Number
			_options: Object
			_terminator
		}
		public {
			Array: class
			Block: class
			Control: class
			Expression: class
			Fragment: class
			Line: class
			Object: class
		}
		constructor(options) { // {{{
			@options = Object.merge({
				indent: {
					level: 0
					style: 'tab'
					size: 4
				}
				terminator: ';\n'
				classes: {
					array: ArrayWriter
					block: BlockWriter
					control: ControlWriter
					expression: ExpressionWriter
					fragment: Fragment
					line: LineWriter
					object: ObjectWriter
				}
			}, options)
			
			@indent = @options.indent.level
			
			@Array = @options.classes.array
			@Block = @options.classes.block
			@Control = @options.classes.control
			@Expression = @options.classes.expression
			@Fragment = @options.classes.fragment
			@Line = @options.classes.line
			@Object = @options.classes.object
			
			@terminator = this.newFragment(@options.terminator)
		} // }}}
		line(...args) { // {{{
			this.newLine(@indent).code(...args).done()
			
			return this
		} // }}}
		newArray(indent = @indent) { // {{{
			@cache.array[indent] ??= new this.Array(this, indent)
		
			return @cache.array[indent].init()
		} // }}}
		newBlock(indent = @indent) { // {{{
			@cache.block[indent] ??= new this.Block(this, indent)
		
			return @cache.block[indent].init()
		} // }}}
		newControl(indent = @indent, addFinalNewLine = true) { // {{{
			return new this.Control(this, indent, addFinalNewLine)
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
			_writer: Writer
			_indent: Number
			_line	= null
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
				
				@writer.push(@writer.newFragment(',\n'))
			}
			else {
				@writer.push(@writer.newFragment('\n'))
			}
			
			return @line = @writer.newExpression(@indent + 1)
		} // }}}
	}
	
	class BlockWriter {
		private {
			_writer: Writer
			_indent: Number
			_undone: Boolean	= true
		}
		constructor(@writer, @indent)
		done() { // {{{
			if @undone {
				@writer.push(@writer.newIndent(@indent), @writer.newFragment('}'))
				
				@undone = false
				
				return true
			}
			else {
				return false
			}
		} // }}}
		private init() { // {{{
			@writer.push(@writer.newFragment(' {\n'))
			
			@undone = true
			
			return this
		} // }}}
		line(...args) { // {{{
			@writer.newLine(@indent + 1).code(...args).done()
			
			return this
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
			_addFinalNewLine: Boolean
			_writer: Writer
			_firstStep: Boolean			= true
			_indent: Number
			_step
		}
		constructor(@writer, @indent, @addFinalNewLine = true) { // {{{
			@step = @writer.newExpression(@indent)
		} // }}}
		code(...args) { // {{{
			@step.code(...args)
			
			return this
		} // }}}
		done() { // {{{
			if @step.done() && @addFinalNewLine {
				@writer.push(@writer.newFragment('\n'))
			}
		} // }}}
		isFirstStep() => @firstStep
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
				if @addFinalNewLine {
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
			_writer: Writer
			_indent: Number
			_undone: Boolean	= true
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
	
	class LineWriter extends ExpressionWriter {
		done() { // {{{
			if @undone {
				@writer.push(@writer._terminator)
				
				@undone = false
			}
		} // }}}
	}
	
	class ObjectWriter {
		private {
			_writer: Writer
			_indent: Number
			_line				= null
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
				
				@writer.push(@writer.newFragment(',\n'))
			}
			else {
				@writer.push(@writer.newFragment('\n'))
			}
			
			return @line = @writer.newExpression(@indent + 1)
		} // }}}
	}
}