module brainfuck;
import std::io;
import std::collections::list;
import std::collections::map;
// import intmap;

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

alias alloc = allocator::mem;

struct Token
{
	char repeats;
	TokenType type;
}

const MEM_SIZE = 30000;

usz mem_ptr;
char[MEM_SIZE] mem;
Token tok;
// Token[TOKEN_BUF_SIZE] prog;

const TOKEN_BUF_SIZE = 300000;

List {usz} loops;

// TODO: try rewriting it as a glfw shader and see what happens
fn int main(String[] args)
{
	// String input = "++++++++[>+++++++++>+++++++++++++>++++++>++++>+++++++++++<<<<<-]>.>---.+++++++..+++.>----.>.>-.<<<.+++.------.--------.>>+.";
	String input = (String)file::load(alloc, args[1])!!;
	// TODO: use the array directly, more speed
	// prog.init_wrapping_array(/*allocator::mem*/null, tok_buf[..]);
	// defer prog.free();
	Token[TOKEN_BUF_SIZE] prog @noinit;
	usz[TOKEN_BUF_SIZE] jmp_idxs @noinit;
	usz prog_idx;

	loops.init(alloc);

	// TODO: statically compute the relative distance between matching '[' and ']' and store in hashmap, so I can just do 'prog_idx = map[prog_idx]' because the key will be its own array index
	foreach (ch : input)
	{
		if (@ok(@enum_from_value(TokenType, tok, ch)) && ch != '\0')
		{
			if (prog_idx > 0 && prog[prog_idx - 1].type.tok == ch && ch != '[' && ch != ']' && prog[prog_idx - 1].repeats < char.max)
			{
				prog[prog_idx - 1].repeats ++;
			}
			else
			{
				if (ch == '[')
				{
					loops.push(prog_idx);
					// prog[prog_idx ++] = {1, .type = @enum_from_value(TokenType, tok, ch)!!};
				}
				else if (ch == ']')
				{
					usz matching_start = loops.pop()!!;
					jmp_idxs[matching_start] = prog_idx;
					jmp_idxs[prog_idx] = matching_start;
					// prog[prog_idx ++] = {1, .type = @enum_from_value(TokenType, tok, ch)!!};
				}
				//else
				//{
				prog[prog_idx ++] = {1, @enum_from_value(TokenType, tok, ch)!!};
				//}
			}
		}
	}
	loops.free();
	prog[prog_idx] = {0, EOF};
	prog_idx = 0;

	// while OUTER: (true){
	switch O: (TokenType.GET_) @jump
	{
		case GET:
			prog_idx ++;
			nextcase;
		case GET_:
			tok = prog[prog_idx];
			debug("Prog idx: %s", prog_idx);
			debug("Token: %s %s", tok.type, tok.repeats);
			nextcase tok.type;
		case INC:
			mem[mem_ptr] += tok.repeats;// (char)(tok.repeats % char.max);
			nextcase GET;
		case DEC:
			mem[mem_ptr] -= tok.repeats;// (char)(tok.repeats % char.max);
			nextcase GET;
		case NEXT:
			mem_ptr += tok.repeats;
			// if (mem_ptr >= MEM_SIZE) mem_ptr -= MEM_SIZE;
			nextcase GET;
		case PREV:
			//if (mem_ptr >= tok.repeats)
			//{
				mem_ptr -= tok.repeats;
			//}
			/*else
			{
				abort();
				// TODO: probably wrong
				mem_ptr = MEM_SIZE - ((usz)tok.repeats - mem_ptr);
			}*/
			nextcase GET;
		case PRINT:
			for (usz j = 0; j < tok.repeats; j++) io::putchar(mem[mem_ptr]) @inline;
			debug("printing: %d", mem[mem_ptr]);
			nextcase GET;
		case READ:
			mem[mem_ptr] = io::stdin()@inline.read_byte()@inline!!;
			nextcase GET;
		case LOOP_S:
			if (mem[mem_ptr] == 0) {
				/*usz num = 1;
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
				}*/
				prog_idx = jmp_idxs[prog_idx];
				debug("jumped forward to %s", prog_idx);
			}
			nextcase GET;
		case LOOP_E:
			if (mem[mem_ptr] != 0) {
				/*usz num = 1;
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
				}*/
				prog_idx = jmp_idxs[prog_idx];
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
