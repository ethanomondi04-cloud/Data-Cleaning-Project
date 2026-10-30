# Data-Cleaning-Project

# Premier League Data Cleaning Project

## Project Overview

This project focuses on cleaning and combining English Premier League player and match data. The original datasets contained missing values, inconsistent team names, different date formats, and information that needed to be reorganized.

The goal was to clean the data so it could be used for analysis and comparisons between player performance and club performance.

## Datasets Used

This project uses two datasets:

- **Player Dataset:** Contains information about Premier League players, including age, nationality, position, goals, assists, and other statistics.
- **Match Dataset:** Contains historical Premier League match information, including teams, scores, dates, and match results.


## Data Cleaning Steps

The following steps were used to clean the datasets:

1. **Loaded the data:** Imported the player and match datasets into R. The player dataset was originally in ARFF format. Read the data in as text then converted it into a table

2. **Cleaned column names:** Converted column names to lowercase and replaced special characters to make them easier to work with.

3. **Cleaned player information:** Removed extra characters and spaces from player names and standardized club names.

4. **Handled missing values:** Replaced missing nationalities with "Unknown" and filled the missing player age using the median age.

5. **Fixed percentage columns:** Removed percentage symbols and converted the values into numeric data.

6. **Handled player statistics:** Players with zero appearances were given missing values for statistics that could not be calculated.

7. **Cleaned match information:** Removed unnecessary columns and corrected inconsistent club names.

8. **Fixed date formats:** Converted dates into a consistent date format and created a season column based on the match date.

9. **Organized match results:** Created a new result column to identify home wins, draws, and away wins. Also separated recent team form into individual columns.

10. **Combined the datasets:** Created summaries of player statistics and match performance for each club, then joined them into one dataset.

## Final Output

The project produces four files:

- `players_clean.csv` – Cleaned player information and statistics.
- `matches_clean.csv` – Cleaned match information and results.
- `club_merged.csv` – Combined player and club performance summaries.
- `goals_vs_win_rate.png` – Scatterplot comparing total player goals with historical club win rates.

## Visualization

The final scatterplot compares the total Premier League goals of players in each club's squad with the club's historical win rate from 2000–2018.
