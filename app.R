library(shiny)
library(dplyr)
library(readr)
library(tidyr)
library(ggplot2)
library(ggrepel)

# =============================================================================
# Real Kano renderer: two blue wings, pink outer circle, purple inner circle
# =============================================================================
plot_kano_real <- function(nodes,
                           title_txt = "Kano plot",
                           subtitle_txt = "") {
    
    nd <- as.data.frame(nodes, stringsAsFactors = FALSE)
    
    required_cols <- c("name", "value", "value2", "size_plot", "fill_col")
    missing_cols <- setdiff(required_cols, names(nd))
    
    if (length(missing_cols) > 0) {
        stop("Missing Kano columns: ", paste(missing_cols, collapse = ", "))
    }
    
    nd$name <- as.character(nd$name)
    nd$value <- suppressWarnings(as.numeric(nd$value))
    nd$value2 <- suppressWarnings(as.numeric(nd$value2))
    nd$size_plot <- suppressWarnings(as.numeric(nd$size_plot))
    
    nd <- nd[
        is.finite(nd$value) &
            is.finite(nd$value2) &
            !is.na(nd$name) &
            nzchar(nd$name),
        ,
        drop = FALSE
    ]
    
    if (nrow(nd) < 2) {
        stop("At least two valid authors are required for the Kano plot.")
    }
    
    nd$size_plot[!is.finite(nd$size_plot) | nd$size_plot <= 0] <- 0.01
    nd$fill_col[is.na(nd$fill_col) | nd$fill_col == ""] <- "green"
    
    # Coordinate origin stays near the lower-left.
    center_x <- 0
    center_y <- 0
    
    span <- max(
        max(nd$value, na.rm = TRUE),
        max(nd$value2, na.rm = TRUE),
        1
    )
    
    # Blue Kano wings.
    t <- seq(0, 1, length.out = 400)
    spread_x <- span * 0.42
    spread_y <- span * 0.55
    
    lower_curve <- data.frame(
        x = center_x + t * spread_x,
        y = center_y - spread_y * (1 - t)^2
    )
    
    # Begin the upper wing in the upper-left quadrant, rather than at (0, 0).
    # This keeps its left end at x < 0 and y > 0, as in the reference Kano plot.
    upper_x_shift <- spread_x * 0.38
    upper_y_lift <- spread_y * 0.45
    upper_curve <- data.frame(
        x = center_x - upper_x_shift + t * spread_x,
        y = center_y + upper_y_lift + spread_y * t^2
    )
    
    wing_poly <- rbind(
        upper_curve,
        lower_curve[rev(seq_len(nrow(lower_curve))), ]
    )
    
    # Pink/purple circles.
    theta <- seq(0, 2 * pi, length.out = 500)
    
    outer_radius <- span * 0.31
    inner_radius <- span * 0.11
    
    outer_circle <- data.frame(
        x = center_x + outer_radius * cos(theta),
        y = center_y + outer_radius * sin(theta)
    )
    
    inner_circle <- data.frame(
        x = center_x + inner_radius * cos(theta),
        y = center_y + inner_radius * sin(theta)
    )
    
    x_max <- max(max(nd$value2, na.rm = TRUE) + span * 0.30, span * 0.85)
    y_max <- max(max(nd$value, na.rm = TRUE) + span * 0.28, span * 0.95)
    
    ggplot(nd, aes(x = value2, y = value)) +
        geom_vline(
            xintercept = 0,
            colour = "red",
            linetype = "dotted",
            linewidth = 0.9
        ) +
        geom_hline(
            yintercept = 0,
            colour = "red",
            linetype = "dotted",
            linewidth = 0.9
        ) +
        geom_polygon(
            data = wing_poly,
            aes(x = x, y = y),
            inherit.aes = FALSE,
            fill = "lightskyblue1",
            alpha = 0.18,
            colour = NA
        ) +
        geom_path(
            data = outer_circle,
            aes(x = x, y = y),
            inherit.aes = FALSE,
            colour = "hotpink3",
            linewidth = 0.45
        ) +
        geom_polygon(
            data = inner_circle,
            aes(x = x, y = y),
            inherit.aes = FALSE,
            fill = "white",
            colour = NA
        ) +
        geom_path(
            data = inner_circle,
            aes(x = x, y = y),
            inherit.aes = FALSE,
            colour = "purple",
            linewidth = 0.6
        ) +
        geom_line(
            data = lower_curve,
            aes(x = x, y = y),
            inherit.aes = FALSE,
            colour = "blue",
            linewidth = 2.3
        ) +
        geom_line(
            data = upper_curve,
            aes(x = x, y = y),
            inherit.aes = FALSE,
            colour = "blue",
            linewidth = 2.3
        ) +
        geom_point(
            aes(size = size_plot, fill = fill_col),
            shape = 21,
            colour = "black",
            alpha = 0.90
        ) +
        geom_text_repel(
            aes(label = name),
            size = 3.0,
            max.overlaps = 150,
            box.padding = 0.35
        ) +
        scale_fill_identity() +
        scale_size_area(max_size = 14, name = "SHC (%)") +
        coord_cartesian(
            xlim = c(-span * 0.08, x_max),
            ylim = c(-span * 0.24, y_max),
            clip = "off"
        ) +
        labs(
            title = title_txt,
            subtitle = subtitle_txt,
            x = "X: first/last-author edge count",
            y = "Y: document count"
        ) +
        theme_minimal(base_size = 13) +
        theme(
            plot.title = element_text(
                face = "bold",
                hjust = 0.5,
                size = 16
            ),
            plot.subtitle = element_text(
                face = "bold",
                hjust = 0.5,
                size = 10,
                lineheight = 1.40
            ),
            plot.margin = margin(18, 120, 25, 40),
            legend.position = "right"
        )
}

# =============================================================================
# User interface
# =============================================================================
ui <- fluidPage(
    titlePanel("First and Corresponding Author Analysis"),
    
    sidebarLayout(
        sidebarPanel(
            fileInput("file", "Upload CSV file", accept = ".csv"),
            radioButtons(
                "strip_parentheses",
                "Author-name cleanup",
                choices = c("Remove parenthetical text (default)" = "remove",
                            "Keep parenthetical text" = "keep"),
                selected = "remove"
            ),
            helpText("Required columns: PT = first author; LA = corresponding author."),
            downloadButton("download_metrics", "Download author metrics")
        ),
        
        mainPanel(
            h3("Dataset summary"),
            tableOutput("summary"),
            
            h3("Kano plot"),
            plotOutput("kano_plot", height = "1000px", width = "100%"),
            
            h3("Author metrics"),
            tableOutput("metrics"),
            
            h3("Author with largest n*"),
            tableOutput("top_n_star"),
            
            h3("Definitions"),
            tags$ul(
                tags$li("Only rows with valid PT and LA names are retained."),
                tags$li("n: retained valid dataset row count."),
                tags$li("n*: first_n + corresponding_n + simple_n."),
                tags$li("CLI: LA_count / (LA_count + PT_count), excluding PT = LA rows."),
                tags$li("AAC: calculated from the top three author role counts."),
                tags$li("MAT: proportion of retained rows where an author appears in neither PT nor LA."),
                tags$li("SHC: 1 − Burt constraint in the PT–LA author-link network."),
                tags$li("CLI bubble colors: ≥0.80 red; ≥0.60 blue; ≥0.40 yellow; ≥0.20 black; otherwise green.")
            )
        )
    )
)

# =============================================================================
# Server
# =============================================================================
server <- function(input, output, session) {
    
    author_data <- reactive({
        req(input$file)
        
        # name_repair = unique fixes trailing unnamed columns in physics.csv.
        raw <- read_csv(
            input$file$datapath,
            show_col_types = FALSE,
            name_repair = "unique"
        ) |>
            select(any_of(c("PT", "LA")))
        
        validate(
            need(
                all(c("PT", "LA") %in% names(raw)),
                "CSV must contain PT (first author) and LA (corresponding author)."
            )
        )
        
        dat <- raw |>
            transmute(
                first_author = trimws(as.character(PT)),
                corresponding_author = trimws(as.character(LA))
            )

        # Default cleanup turns "Xue, Qikun(Hong Kong)" into "Xue, Qikun".
        if (identical(input$strip_parentheses, "remove")) {
            dat <- dat |>
                mutate(
                    first_author = trimws(gsub("\\s*\\([^()]*\\)", "", first_author)),
                    corresponding_author = trimws(gsub("\\s*\\([^()]*\\)", "", corresponding_author))
                )
        }

        dat <- dat |>
            filter(
                !is.na(first_author),
                first_author != "",
                !is.na(corresponding_author),
                corresponding_author != ""
            ) |>
            mutate(paper_id = row_number())
        
        validate(need(nrow(dat) > 0, "No valid PT/LA rows were found."))
        dat
    })
    
    # ---------------------------------------------------------------------------
    # PT-LA role network and author-level Burt constraint / SHC
    # ---------------------------------------------------------------------------
    shc_from_network <- function(dat) {
        authors <- sort(unique(c(dat$first_author, dat$corresponding_author)))
        
        edge_rows <- dat |>
            filter(first_author != corresponding_author) |>
            count(first_author, corresponding_author, name = "weight")
        
        w <- matrix(
            0,
            nrow = length(authors),
            ncol = length(authors),
            dimnames = list(authors, authors)
        )
        
        if (nrow(edge_rows) > 0) {
            for (i in seq_len(nrow(edge_rows))) {
                a <- edge_rows$first_author[i]
                b <- edge_rows$corresponding_author[i]
                
                w[a, b] <- w[a, b] + edge_rows$weight[i]
                w[b, a] <- w[b, a] + edge_rows$weight[i]
            }
        }
        
        strength <- rowSums(w)
        edge_n <- rowSums(w > 0)
        non_isolated <- strength > 0
        
        p <- matrix(0, nrow = nrow(w), ncol = ncol(w))
        
        if (any(non_isolated)) {
            p[non_isolated, ] <- w[non_isolated, , drop = FALSE] /
                strength[non_isolated]
        }
        
        # Burt constraint:
        # C_i = sum_j [p_ij + sum_q(p_iq * p_qj)]^2
        indirect <- p %*% p
        diag(indirect) <- 0
        
        constraint <- rowSums((p + indirect)^2)
        constraint[!non_isolated] <- NA_real_
        
        tibble(
            author = authors,
            edge = as.integer(edge_n),
            edge_weight = as.numeric(strength),
            Burt_constraint = constraint,
            SHC = pmax(0, pmin(1, 1 - constraint)),
            SHC_percent = 100 * SHC
        )
    }
    
    # ---------------------------------------------------------------------------
    # Metrics
    # ---------------------------------------------------------------------------
    metrics <- reactive({
        dat <- author_data()
        total_rows <- nrow(dat)
        
        roles <- bind_rows(
            dat |>
                transmute(
                    author = first_author,
                    first_n = 1L,
                    corresponding_n = 0L
                ),
            dat |>
                transmute(
                    author = corresponding_author,
                    first_n = 0L,
                    corresponding_n = 1L
                )
        )
        
        role_counts <- roles |>
            group_by(author) |>
            summarise(
                first_n = sum(first_n),
                corresponding_n = sum(corresponding_n),
                role_count = first_n + corresponding_n,
                .groups = "drop"
            )
        
        simple_counts <- dat |>
            filter(first_author == corresponding_author) |>
            count(author = first_author, name = "simple_n")
        
        # CLI excludes PT == LA rows.
        multi_dat <- dat |>
            filter(first_author != corresponding_author)
        
        multi_role_counts <- bind_rows(
            multi_dat |>
                transmute(
                    author = first_author,
                    first_multi_n = 1L,
                    corresponding_multi_n = 0L
                ),
            multi_dat |>
                transmute(
                    author = corresponding_author,
                    first_multi_n = 0L,
                    corresponding_multi_n = 1L
                )
        ) |>
            group_by(author) |>
            summarise(
                first_multi_n = sum(first_multi_n),
                corresponding_multi_n = sum(corresponding_multi_n),
                .groups = "drop"
            )
        
        # AAC from top 3 role counts.
        top_counts <- sort(role_counts$role_count, decreasing = TRUE)
        
        AAC <- if (
            length(top_counts) >= 3 &&
            top_counts[2] > 0 &&
            top_counts[3] > 0
        ) {
            ratio <- (top_counts[1] / top_counts[2]) /
                (top_counts[2] / top_counts[3])
            
            ratio / (1 + ratio)
        } else {
            NA_real_
        }
        
        # MAT: author absent from both PT and LA in each valid record.
        mat_table <- tibble(
            author = role_counts$author,
            MAT = vapply(
                role_counts$author,
                function(a) {
                    mean(
                        dat$first_author != a &
                            dat$corresponding_author != a
                    )
                },
                numeric(1)
            )
        )
        
        role_counts |>
            left_join(simple_counts, by = "author") |>
            left_join(multi_role_counts, by = "author") |>
            left_join(mat_table, by = "author") |>
            left_join(shc_from_network(dat), by = "author") |>
            mutate(
                across(
                    c(simple_n, first_multi_n, corresponding_multi_n),
                    ~ replace_na(.x, 0L)
                ),
                
                n = total_rows,
                
                n_star = first_n + corresponding_n + simple_n,
                
                CLI = if_else(
                    first_multi_n + corresponding_multi_n > 0,
                    corresponding_multi_n /
                        (first_multi_n + corresponding_multi_n),
                    NA_real_
                ),
                
                AAC = AAC,
                
                CLI_color = case_when(
                    CLI >= 0.80 ~ "red",
                    CLI >= 0.60 ~ "blue",
                    CLI >= 0.40 ~ "yellow",
                    CLI >= 0.20 ~ "black",
                    TRUE ~ "green"
                )
            ) |>
            select(
                author,
                n,
                n_star,
                first_n,
                corresponding_n,
                simple_n,
                CLI,
                CLI_color,
                AAC,
                MAT,
                edge,
                edge_weight,
                Burt_constraint,
                SHC,
                SHC_percent,
                role_count
            ) |>
            arrange(desc(role_count), author)
    })
    
    # ---------------------------------------------------------------------------
    # Dataset summary
    # ---------------------------------------------------------------------------
    output$summary <- renderTable({
        dat <- author_data()
        
        data.frame(
            retained_valid_rows = nrow(dat),
            same_PT_LA_rows = sum(dat$first_author == dat$corresponding_author),
            nonself_PT_LA_rows = sum(dat$first_author != dat$corresponding_author),
            distinct_first_authors = n_distinct(dat$first_author),
            distinct_corresponding_authors = n_distinct(dat$corresponding_author)
        )
    })
    
    # ---------------------------------------------------------------------------
    # Kano plot
    # ---------------------------------------------------------------------------
    output$kano_plot <- renderPlot({
        m <- metrics()
        
        validate(
            need(nrow(m) >= 3, "At least three authors are required for the Kano plot.")
        )
        
        top <- m |>
            slice_max(role_count, n = 1, with_ties = FALSE)
        
        # Display only the 20 highest role-count authors on the Kano plot.
        # The complete metrics table and CSV download remain unchanged.
        m_plot <- m |>
            slice_max(role_count, n = min(20L, nrow(m)), with_ties = FALSE)

        kano_nodes <- data.frame(
            name = m_plot$author,
            value = m_plot$role_count,
            value2 = m_plot$edge,
            size_plot = pmax(m_plot$SHC_percent, 0.01),
            fill_col = m_plot$CLI_color,
            stringsAsFactors = FALSE
        )
        
        # Exactly two annotation rows.
        annotation_row_1 <- sprintf(
            "AAC=%.3f  |  SHC (= 1 - Burt constraint)=%.3f (%.1f%%)  |  CLI=%.3f",
            top$AAC,
            top$SHC,
            top$SHC_percent,
            top$CLI
        )
        
        annotation_row_2 <- sprintf(
            "MAT=%.3f  |  n=%d  |  n*=%d  (1st=%d + corresponding=%d + simple_n=%d)",
            top$MAT,
            top$n,
            top$n_star,
            top$first_n,
            top$corresponding_n,
            top$simple_n
        )
        
        p <- plot_kano_real(
            nodes = kano_nodes,
            title_txt = paste0("Kano plot: ", top$author),
            subtitle_txt = paste(annotation_row_1, annotation_row_2, sep = "\n")
        )
        
        span <- max(
            max(kano_nodes$value, na.rm = TRUE),
            max(kano_nodes$value2, na.rm = TRUE),
            1
        )
        
        # Reserve a wide header band based on the full plot span, not the
        # narrow edge-count range, so all six cards remain separate.
        card_y <- max(kano_nodes$value, na.rm = TRUE) + span * 0.23
        
        cards <- data.frame(
            x = seq(
                from = -span * 0.05,
                to = span * 0.75,
                length.out = 6
            ),
            y = rep(card_y, 6),
            label = c(
                paste0("AAC\n", sprintf("%.3f", top$AAC)),
                paste0("SHC\n", sprintf("%.3f", top$SHC)),
                paste0("CLI\n", sprintf("%.3f", top$CLI)),
                paste0("MAT\n", sprintf("%.1f%%", 100 * top$MAT)),
                paste0("n\n", top$n),
                paste0("n*\n", top$n_star)
            ),
            fill = c(
                "#B7D8F5",
                "#F7C6D9",
                "#CBEBC7",
                "#FFE89A",
                "#DEC9F7",
                "#B9EEF5"
            ),
            stringsAsFactors = FALSE
        )
        
        p +
            # Override the renderer's data-only window to reserve space for
            # the separated metric header and the Top-1 callout.
            coord_cartesian(
                xlim = c(-span * 0.15, span * 1.30),
                ylim = c(-span * 0.30, max(kano_nodes$value, na.rm = TRUE) + span * 0.42),
                clip = "off"
            ) +
            geom_label(
                data = cards,
                aes(x = x, y = y, label = label),
                inherit.aes = FALSE,
                fill = cards$fill,
                colour = "black",
                fontface = "bold",
                size = 4.0,
                label.size = 0.35,
                label.padding = grid::unit(0.28, "lines")
            ) +
            geom_point(
                data = subset(kano_nodes, name == top$author),
                aes(x = value2, y = value),
                inherit.aes = FALSE,
                shape = 21,
                fill = "red",
                colour = "black",
                size = 6,
                stroke = 1.2
            ) +
            annotate(
                "label",
                x = top$edge + span * 0.16,
                y = top$role_count + span * 0.10,
                label = paste0("Top 1 author: ", top$author),
                colour = "black",
                fill = "#FFF3F3",
                label.size = 0.6,
                size = 3.8,
                fontface = "bold"
            ) +
            annotate(
                "segment",
                x = top$edge + span * 0.13,
                y = top$role_count + span * 0.08,
                xend = top$edge,
                yend = top$role_count,
                colour = "red",
                linewidth = 1.0,
                arrow = grid::arrow(length = grid::unit(0.18, "inches"))
            )
    }, width = 1400, height = 1000, res = 120)
    
    output$metrics <- renderTable({
        metrics()
    }, digits = 3)
    
    output$top_n_star <- renderTable({
        metrics() |>
            slice_max(n_star, n = 1, with_ties = TRUE) |>
            select(
                author,
                n,
                n_star,
                first_n,
                corresponding_n,
                simple_n,
                CLI,
                AAC,
                MAT,
                SHC,
                SHC_percent
            )
    }, digits = 3)
    
    output$download_metrics <- downloadHandler(
        filename = function() "author_kano_metrics.csv",
        content = function(file) {
            write_csv(metrics(), file, na = "")
        }
    )
}

shinyApp(ui, server)