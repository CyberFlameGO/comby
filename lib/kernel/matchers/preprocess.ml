open Core_kernel

let debug =
  match Sys.getenv "DEBUG_COMBY" with
  | exception Not_found -> false
  | _ -> true

let map_aliases (module Metasyntax : Metasyntax.S) template parent_rule aliases =
  let module Parser = Rule.Make (Metasyntax) in
  List.fold aliases
    ~init:(template, parent_rule)
    ~f:(fun (template, parent_rule) Types.Metasyntax.{ pattern; match_template; rule } ->
        let open Option in
        match String.substr_index template ~pattern with
        | None -> template, parent_rule
        | Some _ ->
          let template' = String.substr_replace_all template ~pattern ~with_:match_template in
          if debug then Format.printf "Substituted: %s@." template';
          let rule' =
            let rule =
              rule
              >>| Parser.create
              >>| function
              | Ok rule -> rule
              | Error e -> failwith @@ "Could not parse rule for alias entry:"^(Error.to_string_hum e)
            in
            match parent_rule, rule with
            | Some parent_rule, Some rule -> Some (parent_rule @ rule)
            | None, Some rule -> Some rule
            | Some parent_rule, None -> Some parent_rule
            | None, None -> None
          in
          template', rule')
