# Data licences

The MIT licence in `LICENSE` covers the Wordbit source code (Swift, `install.sh`, and the scripts). It does not cover the word lists. Those stay under the licences below. `Resources/words.json` is a mixed file: the English fields and the Chinese field are licensed separately.

## English words — `Resources/words.json`

The 400 entries are the Word of the Day v1 list, in the same order. The fields `word`, `ipa`, `pos`, `definition`, `example`, `origin`, and `source` are unchanged. A `cn` field was added (see ECDICT below).

128 entries have an empty `origin`. The origin line is hidden for those. The kaikki.org cache used to build v1 was not in the source snapshot, so the missing origins were not filled in.

### Wiktionary, via kaikki.org

Definitions, examples, and etymologies marked in `source` as Wiktionary are adapted from [Wiktionary](https://en.wiktionary.org/), licensed under [Creative Commons Attribution-ShareAlike 4.0](https://creativecommons.org/licenses/by-sa/4.0/). The entries were extracted with [Wiktextract](https://github.com/tatuylonen/wiktextract) and distributed by [kaikki.org](https://kaikki.org/).

If you share `words.json` or a list built from these fields, keep this attribution and use a compatible licence for those fields.

### Princeton WordNet 3.0

Some definitions, and some examples, come from WordNet. The `source` field says so when an example is from WordNet, or when the whole entry is.

WordNet Release 3.0

This software and database is being provided to you, the LICENSEE, by Princeton University under the following license. By obtaining, using and/or copying this software and database, you agree that you have read, understood, and will comply with these terms and conditions.:

Permission to use, copy, modify and distribute this software and database and its documentation for any purpose and without fee or royalty is hereby granted, provided that you agree to comply with the following copyright notice and statements, including the disclaimer, and that the same appear on ALL copies of the software, database and documentation, including modifications that you make for internal use or for distribution.

WordNet 3.0 Copyright 2006 by Princeton University. All rights reserved.

THIS SOFTWARE AND DATABASE IS PROVIDED "AS IS" AND PRINCETON UNIVERSITY MAKES NO REPRESENTATIONS OR WARRANTIES, EXPRESS OR IMPLIED. BY WAY OF EXAMPLE, BUT NOT LIMITATION, PRINCETON UNIVERSITY MAKES NO REPRESENTATIONS OR WARRANTIES OF MERCHANTABILITY OR FITNESS FOR ANY PARTICULAR PURPOSE OR THAT THE USE OF THE LICENSED SOFTWARE, DATABASE OR DOCUMENTATION WILL NOT INFRINGE ANY THIRD PARTY PATENTS, COPYRIGHTS, TRADEMARKS OR OTHER RIGHTS.

The name of Princeton University or Princeton may not be used in advertising or publicity pertaining to distribution of the software and/or database. Title to copyright in this software, database and any associated documentation shall at all times remain with Princeton University and LICENSEE agrees to preserve same.

### CMU Pronouncing Dictionary

IPA not taken from Wiktionary comes from the CMU Pronouncing Dictionary (cmudict).

Copyright (C) 1993-2015 Carnegie Mellon University. All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer. The contents of this file are deemed to be source code.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

This work was supported in part by funding from the Defense Advanced Research Projects Agency, the Office of Naval Research and the National Science Foundation of the United States of America, and by member companies of the Carnegie Mellon Sphinx Speech Consortium. We acknowledge the contributions of many volunteers to the expansion and improvement of this dictionary.

THIS SOFTWARE IS PROVIDED BY CARNEGIE MELLON UNIVERSITY ``AS IS'' AND ANY EXPRESSED OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL CARNEGIE MELLON UNIVERSITY NOR ITS EMPLOYEES BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

## Chinese glosses — ECDICT

Short Chinese glosses in `words.json` (`cn`) and `pictures.json` (`cn`) are from [ECDICT](https://github.com/skywind3000/ECDICT) by Linwei (skywind3000).

They are shortened, not copied whole. For the 400 study words, the build keeps the first one or two senses on the line that matches the part of speech. For the picture words, it keeps one concrete sense from that line. Parenthetical asides are removed. A sense that says it is "shaped like" something (形物) is skipped. Three picture words use a later sense from the same ECDICT line, because the first sense was not the concrete one: fountain 喷泉, football 橄榄球, and mushroom 蘑菇 (the "shaped like a mushroom" sense is skipped). `scripts/build_resources.py` checks that those strings really occur in the entry.

**Chinese meanings checked by AI — corrections welcome.** The 400 study glosses and the 156 picture glosses were reviewed by AI, not yet by a native speaker. If one looks wrong, please open an issue.

MIT License

Copyright (c) 2025 Linwei

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

## Pictures

`Resources/pictures.json` does not contain image files. Each `glyph` is an emoji character drawn at runtime with Apple Color Emoji, which ships with macOS. `symbol` is an SF Symbol name used only when `glyph` is empty. The emoji were chosen from Unicode 13 / Emoji 13.1 or older so they exist on macOS 13. SF Symbols and Apple Color Emoji are not redistributed in this repository.
