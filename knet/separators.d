#!/usr/bin/rdmd

/** Separators used in Knowledge Encoding.
 */
module knet.separators;

enum char asciiUS = '';       // ASCII Unit Separator
enum char asciiRS = '';       // ASCII Record Separator
enum char asciiGS = '';       // ASCII Group Separator
enum char asciiFS = '';       // ASCII File Separator

enum syllableSeparator = asciiUS; // separates syllables
enum alternativesSeparator = asciiRS; // separates alternatives
enum roleSeparator = asciiFS; // separates subject from object, translations, etc.

enum qualifierSeparator = ':'; // noun:human
enum meaningNrSeparator = ';'; // tomten;1 tomten;2
enum meaningNrSeparatorString = `:`;
enum countSeparator = '#'; // gives occurrence count
enum expressionWordSeparator = " "; // Lemma Expression Separator.

enum qualifierSeparatorString = [qualifierSeparator]; // noun:human
enum roleSeparatorString = [roleSeparator];
enum countSeparatorString = [countSeparator];
