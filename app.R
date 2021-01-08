#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(shinythemes)

# The Harris–Benedict equations revised by Mifflin and St Jeor in 1990.
# https://pubmed.ncbi.nlm.nih.gov/2305711/
bmr <- function(weight_kg, height_cm, age_years, sex){
    s = switch (sex, 'Male' = 5, 'Female' = -161)
    10.0 * weight_kg + 6.25 * height_cm - 5.0 * age_years + s
}

#  Physical activity levels
# http://www.fao.org/3/y5686e/y5686e07.htm
pal <- function(level){
    switch (level,
        'Sedentary or light activity' = 1.40, # Variable 1.40-1.69
        'Active or moderately active' = 1.70, # Variable 1.70-1.99
        'Vigorously active' = 2.00  # Variable 2.00-2.40
    )
}

# Define UI for application that draws a histogram
ui <- fluidPage(

    theme = shinytheme("lumen"),
    
    # Application title
    titlePanel("TDEE Calculator"),

    # Sidebar with a slider input for number of bins 
    sidebarLayout(
        sidebarPanel(
            textInput(inputId = "weight",
                      label = strong("Weight(in kg)"),
                      value = ""),
            textInput(inputId = "height",
                      label = strong("Height(in cm)"),
                      value = ""),
            textInput(inputId = "age",
                      label = strong("Age:"),
                      value = ""),
            radioButtons("sex",
                         strong("Sex:"),
                         c("Female", "Male")),
            selectInput(inputId = "pal",
                        label = strong("Physical activity level"),
                        choices = unique(c(
                            "Sedentary or light activity",
                            "Active or moderately active",
                            "Vigorously active"
                            )),
                        selected = "Sedentary or light activity")),
        # Show a plot of the generated distribution
        mainPanel(
            h1(textOutput("text")),
            htmlOutput("table")
        )
    )
)

# Define server logic required to draw a histogram
server <- function(input, output) {

    output$text <- renderText({
        if(input$weight > 0 && input$height > 0 && input$age > 0) {
            weight <- as.numeric(input$weight)
            height <- as.numeric(input$height)
            age <- as.numeric(input$age)
            sex <- input$sex
            pal <- pal(input$pal)
            tdee <- bmr(weight, height, age, sex) * pal

            HTML(paste0(round(tdee), " calories per day"))
        }
    })
    
    output$table <- renderTable({
        if(input$weight > 0 && input$height > 0 && input$age > 0) {
            weight <- as.numeric(input$weight)
            height <- as.numeric(input$height)
            age <- as.numeric(input$age)
            sex <- input$sex
            
            df = data.frame(
                 c("Basal Metabolic Rate",
                   "Sedentary or light activity",
                   "Active or moderately active",
                   "Vigorously active"),
                 c(round(bmr(weight, height, age, sex)),
                   round(bmr(weight, height, age, sex) * pal("Sedentary or light activity")),
                   round(bmr(weight, height, age, sex) * pal("Active or moderately active")),
                   round(bmr(weight, height, age, sex) * pal("Vigorously active")))
            )
            
            colnames(df) = c('Activity', 'Calories per day')
            
            # Select and apply the strong tag in the default option
            line = df$Activity == input$pal
            df[line,] = c(sprintf('<strong>%s</strong>', input$pal),
                          sprintf('<strong>%s</strong>', df[line,2]))
            df
        }
    }, sanitize.text.function = function(x){x}, striped = TRUE, hover = TRUE)

}

# Set Options
options(shiny.host = '0.0.0.0')
options(shiny.port = strtoi(Sys.getenv("PORT")))

# Run the application 
shinyApp(ui = ui, server = server)
