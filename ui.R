library(shiny)

shinyUI(fluidPage(
  
  img(src="KummerSurface.jpeg", width=80, align='right'),
  titlePanel("An enhanced t-SNE plot for MNIST digits"),
  
  # suppresses spurious 
  # 'progress' error messages after all the debugging 
  # is done:
  tags$style(type="text/css",
             ".shiny-output-error { visibility: hidden; }",
             ".shiny-output-error:before { visibility: hidden; }"
  ),
  
  # the main stuff:
  HTML("
       <br>
       <p>
       The plot below illustrates how one can enhance a t-SNE (or any other) dimensional
reduction by incorporating class information as well as the distance information among points in the 
high-dimensional space. It should be compared with the original t_SNE plot in Figure 2(a)
of the reference below. My plot below uses the same data as van der Marten and Hinton: a sample
of 6,000 hand-written digits from the MNIST data set.
</p><p>
The plot below gives somewhat sharper separation between the classes. This is because instead
of t-SNE-ing directly from pixel space, I've first used a neural network to give a lower-dimensional
representation that is able to take account of the known classes as well as the pixels. (But
note that we can still use this representation for unseen test digits without knowing their class -- 
we just pass them through the network.)
</p><p>
The network we trained (on the full MNIST training data, and using Torch) has architecture<br>
784 --> 128 --> 128 --> 9 --> 10-way softmax<br>
and got 95% success on test data. We then take the 9-dimensional output in the penultimate layer 
as our lower-dimensional representation. The neural network is then equivalent to a logistic
regression in this 9-dimensional space.
</p><p>
Why 9? Because for 10 classes 9 is the lowest dimension for which one can expect a strong
logistic regression. Namely, the lower part of the network is concentrating the classes near
the 10 vertices of a simplex in this space.
</p>
       <h4>Reference</h4>
       <li>
       <ul> Laurens van der Maaten, Geoffrey Hinton: 
<a href='http://www.cs.toronto.edu/~hinton/absps/tsne.pdf'>Visualizing Data using t-SNE</a>, 
       <i>Journal of Machine Learning Research</li> 1 (2008) 1-48.
       <hr>     
       "),
  
      
      fluidRow(
        column(width = 6,
               helpText("The main plot: 'enhanced' t-SNE of a sample of 6000 MNIST pionts. 
                        Select and drag for zoom ouput:"),
               plotOutput("mainplot", height=600,
                          brush = brushOpts(id = "plot_brush")
                          )
        ),
        column(width = 3,
               helpText("Sample from the zoom region:"),
               plotOutput("plot_brush_sample", height="250px", width="250px"),
               helpText("... and the zoom region itself. Hover to inspect:"),
               plotOutput("plot_brush_subplot", height="300px", width="300px",
                          hover = hoverOpts(id="plot_hover", delayType="throttle")
                          )
        ),
        column(width = 3,
               helpText("Distribution of
                        digits in the
                        zoom region:"),
               tableOutput("plot_brushedpoints"),
               plotOutput("plot_hover", height="250px", width="200px")
        )
      ),
      HTML("
<hr>
&copy Bill Ox 2015 <a href='mailto:box121209@gmail.com'>box121209@gmail.com</a>
           ")
  )
)