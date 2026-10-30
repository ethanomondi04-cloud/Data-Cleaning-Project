# Premier League data cleaning

# install.packages("tidyverse")   
# install.packages("lubridate") 
library(tidyverse)
library(lubridate)

dir.create("cleaned", showWarnings = FALSE)

# 1. Load the data

# The player file is ARFF so I read it as plain text first
lines <- readLines("dataset.")

# column names are in the @ATTRIBUTE lines
attr_lines <- lines[grepl("^@ATTRIBUTE", lines, ignore.case = TRUE)]
col_names <- sub("^@ATTRIBUTE ", "", attr_lines, ignore.case = TRUE)
col_names <- sub(" [A-Za-z]+$", "", col_names)   # remove the type (REAL, STRING...)
col_names <- gsub('"', "", col_names)

# the data starts after the @DATA line
start <- grep("^@DATA", lines, ignore.case = TRUE)
data_lines <- lines[(start + 1):length(lines)]
data_lines <- data_lines[data_lines != ""]
data_lines <- data_lines[!grepl("^%", data_lines)]   

# Turns the data into a table format - researched to find the function read delim and how to use it
players_raw <- read_delim(I(paste(data_lines, collapse = "\n")), delim = ",",
                          col_names = col_names, na = "?",
                          quote = "'", escape_backslash = TRUE,
                          escape_double = FALSE, guess_max = Inf,
                          show_col_types = FALSE)

matches_raw <- read_csv("final_dataset.csv", show_col_types = FALSE)


# missing values depend on position (goalkeepers vs everyone else)
players_raw %>%
  group_by(Position) %>%
  summarise(saves_missing = mean(is.na(Saves)),
            shots_missing = mean(is.na(Shots)),
            tackles_missing = mean(is.na(Tackles)),
            clean_sheets_missing = mean(is.na(Clean_sheets)))

# two date formats (8 characters or 10 characters)
print(table(nchar(matches_raw$Date)))

# Middlesbrough is spelled two ways
print(table(matches_raw$HomeTeam[grepl("^Middles", matches_raw$HomeTeam)]))

# club names in the player file that are not in the match file
print(setdiff(unique(players_raw$Club), unique(matches_raw$HomeTeam)))


players <- players_raw

# easier column names
names(players) <- tolower(names(players))
names(players) <- gsub("%", "pct", names(players))
names(players) <- gsub("/", "_", names(players))

# clean up the player names
players$name <- gsub("\\\\", "", players$name)
players$name <- trimws(players$name)

# make club names match the match file
players$club <- gsub("-", " ", players$club)
players$club <- recode(players$club,
                       "Brighton and Hove Albion" = "Brighton",
                       "Manchester City" = "Man City",
                       "Manchester United" = "Man United",
                       "Newcastle United" = "Newcastle",
                       "Tottenham Hotspur" = "Tottenham",
                       "West Bromwich Albion" = "West Brom",
                       "Wolverhampton Wanderers" = "Wolves",
                       "Leeds United" = "Leeds",
                       "Leicester City" = "Leicester",
                       "West Ham United" = "West Ham")

players$position <- factor(players$position)

# one player has no nationality
players$nationality[is.na(players$nationality)] <- "Unknown"

# Turns the percent columns into numbers
players$shooting_accuracy_pct <- as.numeric(gsub("%", "", players$shooting_accuracy_pct))
players$tackle_success_pct <- as.numeric(gsub("%", "", players$tackle_success_pct))
players$cross_accuracy_pct <- as.numeric(gsub("%", "", players$cross_accuracy_pct))

# one player has no age, so I fill it with the median
players$age_imputed <- is.na(players$age)
players$age[is.na(players$age)] <- median(players$age, na.rm = TRUE)

# goals_per_match in the file is wrong, so I calculate it myself
players$goals_per_match <- players$goals / players$appearances
players$goals_per_match[players$appearances == 0] <- NA

# players with 0 appearances have no real rate values
players$zero_appearances <- players$appearances == 0
players$shooting_accuracy_pct[players$zero_appearances] <- NA
players$tackle_success_pct[players$zero_appearances] <- NA
players$cross_accuracy_pct[players$zero_appearances] <- NA
players$passes_per_match[players$zero_appearances] <- NA


# 4. Clean the matches

# remove the extra index column
matches <- select(matches_raw, -any_of(c("...1", "Unnamed: 0")))

names(matches) <- tolower(names(matches))
matches <- rename(matches, home_team = hometeam, away_team = awayteam)

# Middlesboro and Middlesbrough are the same team
matches$home_team[matches$home_team == "Middlesboro"] <- "Middlesbrough"
matches$away_team[matches$away_team == "Middlesboro"] <- "Middlesbrough"

# some have 2 digit years and some have 4 digit years
long_dates <- nchar(matches$date) == 10
new_date <- as.Date(matches$date, format = "%d/%m/%y")
new_date[long_dates] <- as.Date(matches$date[long_dates], format = "%d/%m/%Y")
matches$date <- new_date

# season starts in August so months before July belong to the previous season
matches$season_start <- ifelse(month(matches$date) >= 7,
                               year(matches$date), year(matches$date) - 1)
matches$season <- paste0(matches$season_start, "/", matches$season_start + 1)

# ftr only has H and NH, so I make a new result column with H, D or A
matches$result <- "D"
matches$result[matches$fthg > matches$ftag] <- "H"
matches$result[matches$fthg < matches$ftag] <- "A"

# form strings like WLMMM have 5 results in one column, so split them up
for (i in 1:5) {
  matches[[paste0("ht_form_", i)]] <- substr(matches$htformptsstr, i, i)
  matches[[paste0("at_form_", i)]] <- substr(matches$atformptsstr, i, i)
}

# M means no match played yet so i replaced it with NA
form_cols <- grep("^(hm|am)[1-5]$|_form_[1-5]$", names(matches), value = TRUE)
for (col in form_cols) {
  matches[[col]][matches[[col]] == "M"] <- NA
}


#Summarize each club and join

# player summary for each club
club_player_summary <- players %>%
  group_by(club) %>%
  summarise(n_players = n(),
            avg_age = mean(age),
            pct_english = mean(nationality == "England"),
            total_goals = sum(goals, na.rm = TRUE),
            total_assists = sum(assists, na.rm = TRUE),
            .groups = "drop")

# put home games and away games in one table 
home <- data.frame(club = matches$home_team, venue = "home",
                   gf = matches$fthg, ga = matches$ftag,
                   win = matches$result == "H", draw = matches$result == "D")
away <- data.frame(club = matches$away_team, venue = "away",
                   gf = matches$ftag, ga = matches$fthg,
                   win = matches$result == "A", draw = matches$result == "D")
club_long <- rbind(home, away)

# match summary for each club
club_match_summary <- club_long %>%
  group_by(club) %>%
  summarise(matches_played = n(),
            win_rate = mean(win),
            draw_rate = mean(draw),
            home_win_rate = mean(win[venue == "home"]),
            away_win_rate = mean(win[venue == "away"]),
            goals_for_pm = mean(gf),
            goals_against_pm = mean(ga),
            .groups = "drop")

# clubs that will not join
print(anti_join(club_player_summary, club_match_summary, by = "club"))

merged <- inner_join(club_player_summary, club_match_summary, by = "club")
print(merged, n = 20)

# 6. Plot and save

ggplot(merged, aes(x = total_goals, y = win_rate, label = club)) +
  geom_point() +
  labs(title = "Squad career goals vs historical win rate",
       x = "Career PL goals of current squad",
       y = "Win rate, 2000-2018") +
  geom_text(vjust = -0.7, size = 3) +
  theme_minimal()
ggsave("cleaned/goals_vs_win_rate.png", width = 8, height = 5)

write_csv(players, "cleaned/players_clean.csv")
write_csv(matches, "cleaned/matches_clean.csv")
write_csv(merged, "cleaned/club_merged.csv")

