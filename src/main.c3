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
	SET_0 = '\0',
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

const TOKEN_BUF_SIZE = 300000;

// TODO: try rewriting it as a glfw shader and see what happens
fn int main(String[] args)
{
	String input @noinit;
	{
		File f = file::from_handle(os::native_fopen(args[1], "rb")) @inline!!;
		defer (void)f.close();
		os::native_fseek(f.file, 0, END)!!;
		input = (String)mem::alloc_array(char, os::native_ftell(f.file) + 1) @inline!!;
		input[^1] = '\x03';
		os::native_fseek(f.file, 0, SET)!!;
		os::native_fread(f.file, input)!!;
	}
	Token[TOKEN_BUF_SIZE] prog @noinit;
	usz[TOKEN_BUF_SIZE] jmp_idxs @noinit;
	usz prog_idx;

	List {usz} loops;
	loops.init(alloc);

	usz input_idx;
	char curr @noinit;
	switch ('\x01') @jump
	{
		default:
			nextcase;
		case '\0':
			input_idx ++;
			if (input_idx >= input.len)
			{
				break;
			}
			nextcase;
		case '\x01':
			curr = input[input_idx];
			nextcase curr;
		case '+':
			@do_thing(prog, prog_idx, INC);
			nextcase '\0';
		case '-':
			@do_thing(prog, prog_idx, DEC);
			nextcase '\0';
		case '>':
			@do_thing(prog, prog_idx, NEXT);
			nextcase '\0';
		case '<':
			@do_thing(prog, prog_idx, PREV);
			nextcase '\0';
		case ',':
			@do_thing(prog, prog_idx, READ);
			nextcase '\0';
		case '.':
			@do_thing(prog, prog_idx, PRINT);
			nextcase '\0';
		case '[':
			if (@unlikely(input_idx + 2 < input.len && input[input_idx + 1] == '-' && input[input_idx + 2] == ']'))
			{
				prog[prog_idx ++] = {1, SET_0};
				input_idx += 2;
			}
			else
			{
				loops.push(prog_idx);
				prog[prog_idx ++] = {1, LOOP_S};
			}
			nextcase '\0';
		case ']':
			usz matching_start = loops.pop()!!;
			jmp_idxs[matching_start] = prog_idx;
			jmp_idxs[prog_idx] = matching_start;

			prog[prog_idx ++] = {1, LOOP_E};
			nextcase '\0';
	}

	loops.free();
	prog[prog_idx] = {0, EOF};
	prog_idx = 0;

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
			mem[mem_ptr] += tok.repeats;
			nextcase GET;
		case DEC:
			mem[mem_ptr] -= tok.repeats;
			nextcase GET;
		case NEXT:
			mem_ptr += tok.repeats;
			nextcase GET;
		case PREV:
			mem_ptr -= tok.repeats;
			nextcase GET;
		case PRINT:
			usz rep = tok.repeats;
			for (usz j = 0; j < rep; j++) io::putchar(mem[mem_ptr]) @inline;
			debug("printing: %d", mem[mem_ptr]);
			nextcase GET;
		case READ:
			mem[mem_ptr] = io::stdin()@inline.read_byte()@inline!!;
			nextcase GET;
		case LOOP_S:
			if (@likely(mem[mem_ptr] == 0)) {
				prog_idx = jmp_idxs[prog_idx];
				debug("jumped forward to %s", prog_idx);
			}
			nextcase GET;
		case LOOP_E:
			if (@likely(mem[mem_ptr] != 0)) {
				prog_idx = jmp_idxs[prog_idx];
				debug("jumped backward to %s", prog_idx);
			}
			nextcase GET;
		case SET_0:
			mem[mem_ptr] = 0;
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

macro @do_thing(Token[TOKEN_BUF_SIZE] #prog, usz #prog_idx, TokenType $t)
{
	if (#prog_idx > 0 && #prog[#prog_idx - 1].type == $t && #prog[#prog_idx - 1].repeats < char.max)
	{
		#prog[#prog_idx - 1].repeats ++;
	}
	else
	{
		#prog[#prog_idx ++] = {1, $t};
	}

}
