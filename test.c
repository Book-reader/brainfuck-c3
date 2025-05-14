#include <stdio.h>
#include <assert.h>
#include <limits.h>

#define MEM_SIZE 30000
#define FILE_BUF_SIZE 300000
#define TOKEN_BUF_SIZE 300000

// #define GET_ 0
#define BREAK_ 0

typedef struct {
	unsigned char type;
	unsigned char repeats;
} Token;

int main(int argc, char **argv)
{
	unsigned char mem[MEM_SIZE];
	unsigned char file_buf[FILE_BUF_SIZE];
	Token toks[TOKEN_BUF_SIZE] = {0};
	size_t token_buf_idx = 0;
	size_t file_buf_size = 0;
	size_t mem_ptr = 0;

	FILE *bf = fopen(argv[1], "r");

	while (!feof(bf)) {
		unsigned char ch = fgetc(bf);
		if (ch == -1) break;
		file_buf[file_buf_size++] = ch;
		assert(file_buf_size < FILE_BUF_SIZE);
		
	}

	for (int i = 0; i < file_buf_size; i++) {
		switch (file_buf[i]) {
			case '+':
			case '-':
			case '>':
			case '<':
			case '.':
			case ',':
				if (toks[token_buf_idx - 1].type == file_buf[i]) {
					toks[token_buf_idx - 1].repeats += 1;
				} else {
					toks[token_buf_idx++] = (Token){ file_buf[i], 1 };
				}
				break;
			case '[':
			case ']':
				toks[token_buf_idx++] = (Token){ file_buf[i], 1 };
				break;
			default:
		}
	}
	toks[token_buf_idx++] = (Token) { 0, 1 };
	token_buf_idx = 0;

	Token t;
	goto GET_;
	GET:
		token_buf_idx ++;
	GET_:
		t = toks[token_buf_idx];
		switch (t.type) {
			case BREAK_:
				goto BREAK;
			case '+':
				goto PLUS;
			case '-':
				goto MINUS;
			case '>':
				goto NEXT;
			case '<':
				goto PREV;
			case ',':
				return 1;
			case '.':
				goto PRINT;
			case '[':
				goto LOOP_S;
			case ']':
				goto LOOP_E;
			default:
				return 1;
		}

	
	PLUS:
		mem[mem_ptr] = (mem[mem_ptr] + t.repeats) % (UCHAR_MAX + 1);
		goto GET;
	MINUS:
		mem[mem_ptr] = (mem[mem_ptr] - t.repeats) % (UCHAR_MAX + 1);
		goto GET;
	NEXT:
		mem_ptr += t.repeats;
		goto GET;
	PREV:
		mem_ptr -= t.repeats;
		goto GET;
	PRINT:
		for (int i = 0; i < t.repeats; i++) putchar(mem[mem_ptr]);
		goto GET;
	LOOP_S:
		if (mem[mem_ptr] == 0) {
			size_t num_brackets = 1;
			while (num_brackets != 0) {
				token_buf_idx ++;
				if (toks[token_buf_idx].type == '[') num_brackets ++;
				else if (toks[token_buf_idx].type == ']') num_brackets --;
			}
		}
		goto GET;
	LOOP_E:
		if (mem[mem_ptr] != 0) {
			size_t num_brackets = 1;
			while (num_brackets != 0) {
				token_buf_idx --;
				if (toks[token_buf_idx].type == '[') num_brackets --;
				else if (toks[token_buf_idx].type == ']') num_brackets ++;
			}
		}
		goto GET;
	BREAK:
	return 0;
}
