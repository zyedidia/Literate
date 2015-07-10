// Header files to include
#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>

// Preprocessor definitions
#define OK 0    /* status code for successful run */
#define usage_error 1    /* status code for improper syntax */
#define cannot_open_file 2    /* status code for file access error */ 

#define READ_ONLY 0

// Global variables
int status = OK;    /* exit status of command, initially OK */
char *prog_name;    /* who we are */

long tot_word_count, tot_line_count, tot_char_count; 
    /* total number of words, lines and chars */

// Functions
void wc_print(char *which, long char_count, long word_count, long line_count)
{
    while (*which)
        switch (*which++) {
        case 'l': printf("%8ld", line_count);
            break;
        case 'w': printf("%8ld", word_count);
            break;
        case 'c': printf("%8ld", char_count);
            break;
        default:
            if ((status & 1) == 0) {
                fprintf(stderr, "\nUsage: %s [-lwc] [filename ...]\n", prog_name);
                status |= 1;
            }
        }
}

// The main program
int main(int argc, char **argv)
{
// Variables local to main
int file_count;    /* how many files there are */
char *which;    /* which counts to print */
int silent = 0;    /* nonzero if the silent option was selected */

int fd = 0;

char buffer[BUFSIZ];    /* we read the input into this array */
register char *ptr;    /* the first unprocessed character in buffer */
register char *buf_end;    /* the first unused position in buffer */
register int c;    /* current character or number of characters just read */
int in_word;    /* are we within a word? */
long word_count, line_count, char_count;   
    /* number of words, lines, and characters found in the file so far */

    prog_name = argv[0];
// Set up option selection
which = "lwc";    /* if no option is given, print all three values */
if (argc >1 && *argv[1] == '-') {
    argv[1]++;
    if (*argv [1] == 's') silent = 1, argv [1]++;
    if (*argv [1]) which = argv [1];
    argc--;
    argv++;
}
file_count = argc - 1;

// Process all the files
argc--;
do {
// If a file is given, try to open *(++argv ); continue if unsuccessful
if (file_count > 0 && (fd = open(*(++argv), READ_ONLY)) < 0) {
    fprintf(stderr, "%s: cannot open file %s\n", prog_name, *argv);
    status |= 2;
    file_count--;
    continue;
}

// Initialize pointers and counters
ptr = buf_end = buffer;
line_count = word_count = char_count = 0;
in_word = 0;

// Scan file
while (1) {
// Fill buffer if it is empty; break at end of file
if (ptr >= buf_end) {
    ptr = buffer;
    c = read(fd, ptr, BUFSIZ);
    if (c <= 0) break;
    char_count += c;
    buf_end = buffer + c;
}

    c = *ptr++;
    if (c > ' ' && c < 177) {    /* visible ASCII codes */
        if (!in_word) {
            word_count++;
            in_word = 1;
        }
        continue;
    }
    if (c == '\n') line_count++;
    else if (c != ' ' && c != '\t') continue;
    in_word = 0;    /* c is newline, space, or tab */
}

// Write statistics for file
if (!silent) {
    wc_print(which, char_count, word_count, line_count);
    if (file_count) printf(" %s\n", *argv);    /* not stdin */
    else printf("\n");    /* stdin */
}

// Close file
close(fd);

// Update grand totals
tot_line_count += line_count;
tot_word_count += word_count;
tot_char_count += char_count;

} while (--argc > 0);

// Print the grand totals if there were multiple files
if (file_count > 1 || silent) {
    wc_print(which, tot_char_count, tot_word_count, tot_line_count);
    if (!file_count) printf("\n");
    else printf(" total in %d file%s\n", file_count, file_count > 1 ? "s" : "");
}

    return status;
}


