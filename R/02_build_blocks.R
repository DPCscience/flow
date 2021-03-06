# split code in blocks, divided by calls to control flow or special comments
# the output is a list of calls where each element has a "label" attribute and
# if relevant a block_type attribute

build_blocks <- function(expr){
  # clean block from braces
  if (is.call(expr) && expr[[1]] == quote(`{`))
    calls <- as.list(expr[-1])
  else
    calls <- list(expr)

  # support empty calls (`{}`)
  if (!length(calls)) {
    blocks <- list(substitute()) # substitute() returns an empty call
    return(blocks)
  }
  # logical indices of control flow calls
  cfc_lgl <- calls %call_in% c("if", "for", "while", "repeat")

  # logical indices of comment calls `#`()
  special_comment_lgl <- calls %call_in% c("#")

  # there are 2 ways to start a block : be a cf not preceded by com, or be a com
  # there are 2 ways to finish a block : be a cf (and finish on next one), or start another block and finish right there

  # cf not preceded by com
  cfc_unpreceded_lgl <- cfc_lgl & !c(FALSE, head(special_comment_lgl, -1))
  # new_block (first or after cfc)
  new_block_lgl <- c(TRUE, head(cfc_lgl, -1))
  block_ids <- cumsum(special_comment_lgl | cfc_unpreceded_lgl | new_block_lgl)

  blocks <- split(calls, block_ids)

  # add empty label to all blocks
  for (i in block_ids) {
    attr(blocks[[i]], "label") <- ""
  }

  # make the comment  label when relevant
  for (i in block_ids[special_comment_lgl]) {
    label <- blocks[[c(i,1,2)]]
    # remove comment from block
    blocks[[i]] <- blocks[[i]][-1]
    attr(blocks[[i]], "label") <- label
  }

  # subset control flows, which contain only one call
  for (i in block_ids[cfc_lgl]) {
    # backup label before subsetting
    label <- attr(blocks[[i]], "label")
    blocks[[i]] <- blocks[[i]][[1]]
    attr(blocks[[i]], "label") <- label
    attr(blocks[[i]], "block_type") <- as.character(blocks[[c(i,1)]])
  }
  blocks
}
