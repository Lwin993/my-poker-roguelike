package com.github.jisaaa.poker.config;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.jdbc.core.JdbcTemplate;

import javax.sql.DataSource;

@Configuration
@Slf4j
public class SQLiteConfig {

    @Bean
    public CommandLineRunner initSQLite(JdbcTemplate jdbc) {
        return args -> {
            jdbc.execute("PRAGMA journal_mode=WAL");
            jdbc.execute("PRAGMA busy_timeout=5000");
            jdbc.execute("PRAGMA synchronous=NORMAL");
            log.info("SQLite initialized: WAL mode, busy_timeout=5000ms");
        };
    }
}
