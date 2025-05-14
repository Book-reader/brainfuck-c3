module brainfuck;
import std::io;
import std::collections::list;

alias Program = List {Token};

enum TokenType : char (char tok)
{
	// READ = '\0',
	INC = '+',
	DEC = '-',
	NEXT = '>',
	PREV = '<',
	PRINT = '.',
	READ = ',',
	LOOP_S = '[',
	LOOP_E = ']',
	// Don't check for i < array_len each time, instead append EOF to end of instructions and make it call break;
	// EOF = '\0',
}

struct Token
{
	char repeats;
	TokenType type;
}

const MEM_SIZE = 30000;

usz mem_ptr;
char[MEM_SIZE] mem;

extern fn CInt putchar(char ch);

fn int main(String[] args)
{
	String input = "++++++++[>+++++++++>+++++++++++++>++++++>++++>+++++++++++<<<<<-]>.>---.+++++++..+++.>----.>.>-.<<<.+++.------.--------.>>+.";
	Program prog;
	prog.init(allocator::mem);
	defer prog.free();


	foreach (ch : input)
	{
		if (prog.len() > 0 && prog[^1].type.tok == ch && ch != '[' && ch != ']' && prog[^1].repeats < char.max)
		{
			prog[^1].repeats ++;
		}
		else
		{
			prog.push({1, @enum_from_value(TokenType, tok, ch)!!});
		}
	}

	for (usz i = 0, usz len = prog.len(); i < len; i++)
	{
		Token tok = prog[i];
		debug("Prog ptr: %s", mem_ptr);
		debug("Mem: %s", mem[:20]);
		debug("Token type at %s: %s, %s", i, tok.type, tok.repeats);
		switch (tok.type)
		{
			case INC: mem[mem_ptr] += tok.repeats;
			case DEC: mem[mem_ptr] -= tok.repeats;
			case NEXT:
				mem_ptr += tok.repeats;
				if (mem_ptr >= MEM_SIZE) mem_ptr -= MEM_SIZE;
			case PREV:
				if (mem_ptr >= tok.repeats)
				{
					mem_ptr -= tok.repeats;
				}
				else
				{
abort();
					// TODO: probably wrong
					mem_ptr = MEM_SIZE - ((usz)tok.repeats - mem_ptr);
				}
			case PRINT:
				for (usz j = 0; j < tok.repeats; j++) putchar(mem[mem_ptr]);
				debug("%c", mem[mem_ptr]);
			case READ: abort();
			case LOOP_S:
				if (mem[mem_ptr] != 0) break;
				usz num = 1;
				while (num != 0)
				{
					i++;
					switch (prog[i].type)
					{
						case LOOP_S:
							num ++;
						case LOOP_E:
							num --;
						default:
							break;
					}
				}
				debug("jumped forward to %s", i);
			case LOOP_E:
				if (mem[mem_ptr] == 0) break;
				usz num = 1;
				while (num != 0)
				{
					i--;
					switch (prog[i].type)
					{
						case LOOP_S:
							num --;
						case LOOP_E:
							num ++;
						default:
							break;
					}
				}
				debug("jumped backward to %s", i);
		}
	}

	return 0;
}

macro debug(...)
{
	$if $feature(DEBUG):
		io::eprintfn($vasplat);
	$endif
}
