module brainfuck;
import std::io;
import std::collections::list;

def Program = List(<Token>);

enum TokenType : char (char tok)
{
	INC = '+',
	DEC = '-',
	NEXT = '>',
	PREV = '<',
	PRINT = '.',
	READ = ',',
	LOOP_S = '[',
	LOOP_E = ']',
}

struct Token
{
//	union
//	{
		/*usz*/ushort repeats;
//		usz matching_idx;
//	}
	TokenType type;
}

const MEM_SIZE = 30000;

usz prog_ptr;
char[MEM_SIZE] mem;

fn int main(String[] args)
{
	String input = "++++++++[>+++++++++>+++++++++++++>++++++>++++>+++++++++++<<<<<-]>.>---.+++++++..+++.>----.>.>-.<<<.+++.------.--------.>>+.";
	Program prog;
	prog.new_init();
	defer prog.free();


	foreach (ch : input)
	{
		if (prog.len() > 0 && prog.last()!!.type.tok == ch && ch != '[' && ch != ']')
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
		debug("Token type at %s: %s, %s", i, tok.type, tok.repeats);
		debug("Mem: %s", mem[:20]);
		switch (tok.type)
		{
			case INC: mem[prog_ptr] = (char)(mem[prog_ptr] + tok.repeats);
			case DEC: mem[prog_ptr] -= (char)(mem[prog_ptr] - tok.repeats);
			case NEXT:
				prog_ptr += tok.repeats;
				if (prog_ptr > MEM_SIZE) prog_ptr -= MEM_SIZE;
			case PREV:
				if (tok.repeats >= inst_ptr)
				{
					prog_ptr -= tok.repeats;
				}
				else
				{
					prog_ptr = MEM_SIZE - (usz)tok.repeats + prog_ptr;
				}
			case PRINT: debug("%c", mem[prog_ptr]);;
			case READ: unreachable();
			case LOOP_S:
				if (mem[prog_ptr] != 0) break;
				isz num = 1;
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
				if (mem[prog_ptr] == 0) break;
				isz num = 1;
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
