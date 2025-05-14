module brainfuck;
import std::io;
import std::collections::list;

alias Program = List {Token};

enum TokenType : char (char tok)
{
	GET = '\0',
	GET_ = '\0',
	INC = '+',
	DEC = '-',
	NEXT = '>',
	PREV = '<',
	PRINT = '.',
	READ = ',',
	LOOP_S = '[',
	LOOP_E = ']',
	// Don't check for i < array_len each time, instead append EOF to end of instructions and make it call break;
	EOF = '\0',
}

struct Token
{
	char repeats;
	TokenType type;
}

const MEM_SIZE = 30000;

usz mem_ptr;
char[MEM_SIZE] mem;
Token tok;
usz prog_idx;
Program prog;

const TOKEN_BUF_SIZE = 300000;

Token[TOKEN_BUF_SIZE] tok_buf;

fn int main(String[] args)
{
	// String input = "++++++++[>+++++++++>+++++++++++++>++++++>++++>+++++++++++<<<<<-]>.>---.+++++++..+++.>----.>.>-.<<<.+++.------.--------.>>+.";
	String input = (String)file::load(allocator::mem, args[1])!!;
	prog.init_wrapping_array(/*allocator::mem*/null, tok_buf[..]);
	defer prog.free();


	foreach (ch : input)
	{
		if (@ok(@enum_from_value(TokenType, tok, ch)) && ch != '\0')
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
	}
	prog.push({0, EOF});

	// while OUTER: (true){
	switch O: (TokenType.GET_) // @jump
	{
		case GET:
			prog_idx ++;
			nextcase;
		case GET_:
			tok = prog.get(prog_idx);
			debug("Prog idx: %s", prog_idx);
			debug("Token: %s %s", tok.type, tok.repeats);
			// prog_idx ++;
			/*switch (tok.type)
			{
				case INC:
					nextcase O: INC;
				case DEC:
					nextcase O: DEC;
				case NEXT:
					nextcase O: NEXT;
				case PREV:
					nextcase O: PREV;
				case PRINT:
					nextcase O: PRINT;
				case READ: nextcase O: READ;
			}*/
			nextcase tok.type;
		case INC:
			mem[mem_ptr] += tok.repeats;
			nextcase GET;
		case DEC:
			mem[mem_ptr] -= tok.repeats;
			nextcase GET;
		case NEXT:
			mem_ptr += tok.repeats;
			// if (mem_ptr >= MEM_SIZE) mem_ptr -= MEM_SIZE;
			nextcase GET;
		case PREV:
			//if (mem_ptr >= tok.repeats)
			{
				mem_ptr -= tok.repeats;
			}
			/*else
			{
				abort();
				// TODO: probably wrong
				mem_ptr = MEM_SIZE - ((usz)tok.repeats - mem_ptr);
			}*/
			nextcase GET;
		case PRINT:
			for (usz j = 0; j < tok.repeats; j++) io::putchar(mem[mem_ptr]);
			debug("%c", mem[mem_ptr]);
			nextcase GET;
		case READ:
			mem[mem_ptr] = io::stdout().read_byte()!!;
			nextcase GET;
		case LOOP_S:
			if (mem[mem_ptr] == 0) {
				usz num = 1;
				//prog_idx --;
				while (num != 0)
				{
					prog_idx++;
					switch (prog[prog_idx].type)
					{
						case LOOP_S:
							num ++;
						case LOOP_E:
							num --;
						default:
							break;
					}
				}
				debug("jumped forward to %s", prog_idx);
			}
			nextcase GET;
		case LOOP_E:
			if (mem[mem_ptr] != 0) {
				usz num = 1;
				//prog_idx --;
				while (num != 0)
				{
					prog_idx --;
					switch (prog[prog_idx].type)
					{
						case LOOP_S:
							num --;
						case LOOP_E:
							num ++;
						default:
							break;
					}
				}
				debug("jumped backward to %s", prog_idx);
			}
			nextcase GET;
		case EOF: return 0;
	}
}

macro debug(...)
{
	$if $feature(DEBUG):
		io::eprintfn($vasplat);
	$endif
}
