#' Evaluate an expression in a ffdf data environment 
#' 
#' Same functionality as \code{\link{with}}. Please note that you should write
#' your expression as if it is a normal \code{data.frame}. The resulting data.frame
#' however will be a \code{ffdf} data.frame.
#' @method with ffdf 
#' @export
#'
#' @param data \code{\link{ffdf}} data object used as an environment for evaluation.
#' @param expr expression to evaluate.
#' @param ... arguments to be passed to future methods.
#' @return if expression is a \code{vector} a newly created \code{ff} vector will be returned 
#' otherwise if the expression is a data.frame a newly created \code{ffdf} object will be returned.
with.ffdf <- function(data, expr, ...){
   e <- substitute(expr)
   #chunks <- chunk(data, by=2) #debug chunking
   chunks <- chunk(data)
   
   cdat <- data[chunks[[1]],,drop=FALSE]
   res <- eval(e, cdat, enclos=parent.frame())
   
   if (is.vector(res)){
      res <- as.ff(res)
      length(res) <- nrow(data)
      for (i in chunks[-1]){
         res[i] <- eval(e, data[i,,drop=FALSE], enclos=parent.frame())
      }
   }
   else if (is.data.frame(res)){
      res <- as.ffdf(res)
      nrow(res) <- nrow(data)
      for (i in chunks[-1]){
         res[i,] <- eval(e, data[i,,drop=FALSE], enclos=parent.frame())
      }
   }
   res
}

within.ffdf <- function(data, expr, ...){
    expr <- substitute(expr)
    parent <- parent.frame()
    
    #chunks <- chunk(data, by=2) debug chunking
    chunks <- chunk(data)
    cdat <- data[chunks[[1]],,drop=FALSE]
   
    e <- evalq(environment(), cdat, parent)
    eval(expr, e)
    l <- as.list(e)
    
    l <- l[!sapply(l, is.null)]
    del <- setdiff(names(cdat), names(l))
    #delete 
    cdat[del] <- list()
    cdat[names(l)] <- l

    res <- as.ffdf(cdat)
    nrow(res) <- nrow(data)
    for (i in chunks[-1]){
       cdat <- data[i,,drop=FALSE]
       e <- evalq(environment(), cdat, parent)
       eval(expr, e)
       l <- as.list(e)
       l <- l[!sapply(l, is.null)]
       cdat[names(l)] <- l
       cdat[del] <- list()
       res[i,] <- cdat
    }
    res
}