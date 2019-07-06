# cloudypdf
Small tool to merge or split PDF files on the command line

## How to build
You need the opam package manager, a recent version of OCaml, and the dune build system installed on your machine. Install the `camlpdf` package with `opam install camlpdf`. Run `dune build main.exe` and you will get the executable in `_build/default/main.exe`.

## Examples

`main.exe a.pdf 1:2:4 b.pdf` : takes pages 1, 2, 4 from `a.pdf` to `b.pdf`.

`main.exe a.pdf 1:5-8 b.pdf` : takes pages 1, 5, 6, 7, 8 from `a.pdf` to `b.pdf`.

`main.exe a.pdf 4- b.pdf` : takes all the pages counting from page 4 (included) in `a.pdf` to `b.pdf`.

`main.exe a.pdf -7 b.pdf` : takes all the pages before page 7 (included) in `a.pdf` to `b.pdf`.

`main.exe a.pdf 1:5 b.pdf -3:6:8-10:12- c.pdf` : takes pages 1 and 5 from `a.pdf`, pages 1, 2, 3, 6, 8, 9, 10, and all the pages after 12 in `b.pdf`, saves in `c.pdf`.