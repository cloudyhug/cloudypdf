let ( -- ) a b = List.init (b - a + 1) (fun x -> x + a)

type range_element =
  | SinglePage of int
  | LeftBound of int
  | RightBound of int
  | DoubleBound of int * int
  | FullPdf

let parse_range str =
  try
    let range_of_group group_str =
      match String.split_on_char '-' group_str with
      | [""; ""] -> FullPdf
      | [""; end_page] -> RightBound (int_of_string end_page)
      | [start_page; ""] -> LeftBound (int_of_string start_page)
      | [start_page; end_page] -> DoubleBound (int_of_string start_page, int_of_string end_page)
      | [page] -> SinglePage (int_of_string page)
      | _ -> failwith ""
    in
    String.split_on_char ':' str
    |> List.map range_of_group
  with Failure _ -> failwith ("invalid range '" ^ str ^ "'")

let parse_args args args_length =
  let rec parse_args_aux inputs i n =
    if i = n then List.rev inputs else
    if i = n - 1 then List.rev ((args.(i), None) :: inputs) else
    let input_file = args.(i) in
    match parse_range args.(i + 1) with
    | range -> parse_args_aux ((input_file, Some range) :: inputs) (i + 2) n
    | exception Failure _ -> parse_args_aux ((input_file, None) :: inputs) (i + 1) n
  in
  parse_args_aux [] 1 args_length

let prepare_pdf (filename, range_opt) =
  let pdf = Pdfread.pdf_of_file None None filename in
  let number_of_pages = Pdfpage.endpage pdf in
  let range_element_to_numbers = function
    | SinglePage p -> [p]
    | LeftBound start_page -> start_page -- number_of_pages
    | RightBound end_page -> 1 -- end_page
    | DoubleBound (start_page, end_page) -> start_page -- end_page
    | FullPdf -> 1 -- number_of_pages
  in
  let pages_to_cut =
    match range_opt with
    | Some r -> List.map range_element_to_numbers r
    | None -> [1 -- number_of_pages]
  in
  (pdf, List.flatten pages_to_cut)

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
  | 1 | 2 -> print_endline usage
  | n ->
    let output_file = Sys.argv.(n - 1) in
    let args = parse_args Sys.argv (n - 1) in
    try
      let pdfs, ranges = List.map prepare_pdf args |> List.split in
      let merged = Pdfmerge.merge_pdfs true true (List.map fst args) pdfs ranges in
      Pdfwrite.pdf_to_file merged output_file
    with Pdf.PDFError msg -> failwith msg