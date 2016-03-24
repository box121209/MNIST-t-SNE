library(shiny)
source("helpers.R")

coords <- data.frame( cbind(tSNE1, tSNE2) )
labels <- class - 1

shinyServer(
  
  function(input, output, session) {
    
    output$mainplot <- renderPlot({
      par(mai=c(0,0,0,0))
      plot(coords, type='n', axes=FALSE, xlab="", ylab="")
      text(coords, labels=labels, col=class, cex=0.5)
    })
    subsetidx <- reactive({
      res <- brushedPoints(coords, input$plot_brush, "tSNE1", "tSNE2")
      if (nrow(res) == 0) return()
      as.numeric(row.names(res))
    })
    subsetdf <- reactive({
      new.dat[subsetidx(),]
    })
    output$plot_brushedpoints <- renderTable({
      freq <- class[subsetidx()] - 1
      table(freq)
    })
    output$plot_brush_sample <- renderPlot({
      if(is.null(input$plot_brush)) return()
      show.digits(subsetidx())
    })
    output$plot_brush_subplot <- renderPlot({
      tmp <- input$plot_brush
      xmin <- tmp$xmin; xmax <- tmp$xmax
      ymin <- tmp$ymin; ymax <- tmp$ymax
      par(mai=c(0,0,0,0))
      plot(0,0, type='n', xlab="", ylab="", 
           axes=FALSE, frame.plot=TRUE,
           xlim=c(xmin, xmax), ylim=c(ymin, ymax))
      box(col='blue')
      if(is.null(tmp)) return()
      df <- subsetdf()
      labels <- df$class - 1
      text(df$tSNE1, df$tSNE2, labels=labels, col=df$class, cex=2)
    })
    output$plot_hover <- renderPlot({
      res <- nearPoints(subsetdf(), input$plot_hover, 
                        "tSNE1", "tSNE2", threshold=10, maxpoints=1)
      if (nrow(res) == 0)
        return()
      idx <- as.numeric(row.names(res))
      show.digit(idx)
    })
  }
)

