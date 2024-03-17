/**
 *  clockWindow.c - ncurses-clock
 *
 *  This module defines functionality for the ncurses window that draws the clock.
 *  This is the View portion of the MVC pattern. See dateTimeModel for Model and main for
 *  Controller.
 *
 */

#include "clockWindow.h"

static const enum ColorPairType {   // Pairs of colors available for drawing
    COLOR_PAIR_WHITE = 0,
    COLOR_PAIR_GREEN = 1
} ColorPairs;
static int row, col;                // Dimensions of the window

static void printTime(BlockString *currentTime);
static void printDate(char *currentDate);
static void printFooter();
static void cursorToRestPosition();


/**
 * Initialize the ncurses window for displaying the clock
 */
void initClockWindow() {
    WINDOW *window = initscr();
    start_color();

    //bool hasColors = has_colors();
    //bool canChangeColors = can_change_color();

    init_pair(COLOR_PAIR_WHITE, COLOR_WHITE, COLOR_BLACK);
    init_pair(COLOR_PAIR_GREEN, COLOR_GREEN, COLOR_BLACK);
    wbkgd(window, COLOR_PAIR(COLOR_PAIR_WHITE));

    cbreak();
    noecho();

    clear();
    refresh();
}

/*
 * Clear the window contents and reset the dimensions to handle resizing
 */
void resetClockWindow() {
    endwin();
    refresh();
    clear();
    getmaxyx(stdscr, row, col);
}

/*
 * Draw the current state of the window
 */
void updateClockWindow(char *timeBuffer, char *dateBuffer) {

    BlockString *testString = initBlockString(timeBuffer);
    printTime(testString);
    deleteBlockString(&testString);

    printDate(dateBuffer);
    //printFooter();

    cursorToRestPosition();
    refresh();
}

/*
 * Delete the window and clean up
 */
void deleteClockWindow() {
    // TODO: add free()?
    curs_set(1);
    clear();
    endwin();
}

/*
 * Prints the current time from the currentTime BlockString
 */
static void printTime(BlockString *currentTime) {

    attron(COLOR_PAIR(COLOR_PAIR_GREEN));

    BlockLetter *letter = currentTime->head;
    int x = (col - currentTime->width) / 2 ;

    while (letter != NULL) {
        for (int i=0; i < LETTER_HEIGHT; i++) {
            int y = row / 2 - LETTER_HEIGHT + i;
            char *line = (*letter->glyph)[i];
            mvprintw(y, x, "%s", line);
        }
        x += letter->width + INTER_LETTER_SPACE;
        letter = letter->next;
    }

    attroff(COLOR_PAIR(COLOR_PAIR_GREEN));
}

/*
 * Prints the current date from the buffer
 */
static void printDate(char *currentDate) {
    attron(COLOR_PAIR(COLOR_PAIR_WHITE));
    mvprintw(row / 2 + 1, (col - strlen(currentDate)) / 2, "%s", currentDate);
    attroff(COLOR_PAIR(COLOR_PAIR_WHITE));
}

/*
 * Prints a short section of text at the bottom of the screen
 */
static void printFooter() {
    attron(COLOR_PAIR(COLOR_PAIR_GREEN));
    //mvprintw(row - 2, 0, "(Q) quit, (C) countdown, (T) timer");
    mvprintw(row - 2, 0, "(Q) quit");
    mvprintw(row - 1, 0, ":");
    attroff(COLOR_PAIR(COLOR_PAIR_GREEN));
}

/*
 * Moves the cursor to the bottom of the screen
 */
static void cursorToRestPosition() {
    move(row - 1, 1);
}


