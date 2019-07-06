(* a -- b = [a; a + 1; a + 2; ...; b] *)
let ( -- ) a b = List.init (b - a + 1) (fun x -> x + a)

type range_element =
  | SinglePage  of int         (* 1 *)
  | LeftBound   of int          (* 1- *)
  | RightBound  of int         (* -7 *)
  | DoubleBound of int * int  (* 3-5 *)
  | FullPdf                   (* - *)

(* A range is a list of range elements separated by ':' (ex: '1:2:5-6:9-') *)
let range_of_string str =
  try
    let range_element_of_string group_str =
      match String.split_on_char '-' group_str with
      | [""; ""]               -> FullPdf
      | [""; end_page]         -> RightBound (int_of_string end_page)
      | [start_page; ""]       -> LeftBound (int_of_string start_page)
      | [start_page; end_page] -> DoubleBound (int_of_string start_page, int_of_string end_page)
      | [page]                 -> SinglePage (int_of_string page)
      | _                      -> failwith ""
    in
    String.split_on_char ':' str
    |> List.map range_element_of_string
  with Failure _ -> failwith ("invalid range '" ^ str ^ "'")

(* Creates tuples with a filename and a page range from the arguments *)
let parse_args args args_length =
  let rec parse_args_aux inputs i n =
    if i = n then List.rev inputs else
    if i = n - 1 then List.rev ((args.(i), None) :: inputs) else
    let input_file = args.(i) in
    match range_of_string args.(i + 1) with
    | range               -> parse_args_aux ((input_file, Some range) :: inputs) (i + 2) n
    | exception Failure _ -> parse_args_aux ((input_file, None) :: inputs) (i + 1) n
  in
  parse_args_aux [] 1 args_length

(* Processes a tuple, reading the PDF data in the file whose name is provided, and preparing the page list *)
let prepare_pdf (filename, range_opt) =
  let pdf = Pdfread.pdf_of_file None None filename in
  let number_of_pages = Pdfpage.endpage pdf in
  let range_element_to_numbers = function
    | SinglePage p                       -> [p]
    | LeftBound start_page               -> start_page -- number_of_pages
    | RightBound end_page                -> 1          -- end_page
    | DoubleBound (start_page, end_page) -> start_page -- end_page
    | FullPdf                            -> 1          -- number_of_pages
  in
  let pages_to_cut =
    match range_opt with
    | Some r -> List.map range_element_to_numbers r
    | None -> [1 -- number_of_pages]
  in
  (pdf, List.flatten pages_to_cut)

(* Help message *)
let usage =
  "Usage: " ^ Sys.argv.(0) ^ " \
(input_file pages?)+ output_file
input_file, output_file: filenames
pages:
- single page                    1
- several pages                  1:2:3
- a range                        1-5
- a partial range                7-
- a combination of the previous  -4:6:8-10:12-"

let () =
  match Array.length Sys.argv with
  | 1 | 2 -> print_endline usage (* at least an input file and an output file are required *)
  | n ->
    let output_file = Sys.argv.(n - 1) in (* the output file is always the last argument *)
    let args = parse_args Sys.argv (n - 1) in
    try
      let pdfs, ranges = List.map prepare_pdf args |> List.split in
      let merged = Pdfmerge.merge_pdfs true true (List.map fst args) pdfs ranges in
      Pdfwrite.pdf_to_file merged output_file
    with Pdf.PDFError msg -> failwith msg