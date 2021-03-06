related_topics <- function(widget, comparison_item) {
  
  i <- which(grepl("Related topics", widget$title) == TRUE)
  
  res <- lapply(i, create_related_topics_payload, widget = widget)
  res <- do.call(rbind, res)
  
  return(res)
}


create_related_topics_payload <- function(i, widget) {
  
  payload2 <- list()
  payload2$restriction$geo <-  as.list(widget$request$restriction$geo[i, , drop = FALSE])
  payload2$restriction$time <- widget$request$restriction$time[[i]]
  payload2$restriction$complexKeywordsRestriction$keyword <- widget$request$restriction$complexKeywordsRestriction$keyword[[i]]
  payload2$keywordType <- widget$request$keywordType[[i]]
  payload2$metric <- widget$request$metric[[i]]
  payload2$trendinessSettings$compareTime <- widget$request$trendinessSettings$compareTime[[i]]
  payload2$requestOptions$property <- widget$request$requestOptions$property[[i]]
  payload2$requestOptions$backend <- widget$request$requestOptions$backend[[i]]
  payload2$requestOptions$category <- widget$request$requestOptions$category[[i]]
  payload2$language <- widget$request$language[[i]]
  
  url <- paste0(
    "https://www.google.com/trends/api/widgetdata/relatedsearches/csv?req=",
    jsonlite::toJSON(payload2, auto_unbox = T),
    "&token=", widget$token[i],
    "&tz=300&hl=en-US"
  )
  
  res <- curl::curl_fetch_memory(URLencode(url))
  
  stopifnot(res$status_code == 200)
  
  res <- readLines(textConnection(rawToChar(res$content)))
  
  i <- which(grepl("$^", res))[1:2]
  start <- i[1]
  end <- i[2]
  
  top <- read.csv(textConnection(res[(start + 1):(end - 1)]), row.names = NULL)
  top$subject <- rownames(top) 
  rownames(top) <- NULL
  top <- top[, c(2, 1)]
  names(top) <- c("subject", "top")
  
  top <- reshape(
    top,
    varying = "top",
    v.names = "value",
    direction = "long",
    timevar = "related_topics",
    times = "top"
  )
  
  rising <- read.csv(textConnection(res[(end + 1):length(res)]))
  rising$subject <- rownames(rising) 
  rownames(rising) <- NULL
  rising <- rising[, c(2, 1)]
  names(rising) <- c("subject", "rising")
  
  rising <- reshape(
    rising,
    varying = "rising",
    v.names = "value",
    direction = "long",
    timevar = "related_topics",
    times = "rising"
  )
  
  res <- rbind(top, rising)
  res$id <- NULL
  res$geo <-  unlist(payload2$restriction$geo, use.names = FALSE)
  
  return(res)
}