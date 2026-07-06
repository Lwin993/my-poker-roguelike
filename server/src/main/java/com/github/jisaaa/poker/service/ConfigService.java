package com.github.jisaaa.poker.service;

import com.github.jisaaa.poker.domain.dto.ItemDTO;
import com.github.jisaaa.poker.domain.entity.GameConfig;
import com.github.jisaaa.poker.domain.entity.ItemConfig;
import com.github.jisaaa.poker.mapper.GameConfigMapper;
import com.github.jisaaa.poker.mapper.ItemConfigMapper;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.concurrent.ConcurrentHashMap;
import java.util.stream.Collectors;

@Service
@Slf4j
@RequiredArgsConstructor
public class ConfigService implements CommandLineRunner {

    private final GameConfigMapper configMapper;
    private final ItemConfigMapper itemConfigMapper;
    private final ObjectMapper objectMapper;

    private final ConcurrentHashMap<String, String> configCache = new ConcurrentHashMap<>();
    private List<ItemDTO> cachedItems = List.of();

    @Override
    public void run(String... args) {
        reload();
    }

    public void reload() {
        configMapper.selectList(null).forEach(
            c -> configCache.put(c.getConfigKey(), c.getConfigValue())
        );
        cachedItems = itemConfigMapper.selectList(null).stream()
            .map(this::toItemDTO)
            .collect(Collectors.toList());
        log.info("Config loaded: {} keys, {} items", configCache.size(), cachedItems.size());
    }

    public String getConfig(String key) {
        return configCache.get(key);
    }

    /**
     * Get config value parsed as JSON object (List or Map).
     * Returns null if key not found or parse fails.
     */
    @SuppressWarnings("unchecked")
    public Object getConfigAsJson(String key) {
        String val = configCache.get(key);
        if (val == null) return null;
        try {
            return objectMapper.readValue(val, Object.class);
        } catch (Exception e) {
            log.warn("Failed to parse config as JSON: key={}", key, e);
            return null;
        }
    }

    public int getIntConfig(String key, int defaultValue) {
        String val = configCache.get(key);
        if (val == null) return defaultValue;
        try {
            return Integer.parseInt(val);
        } catch (NumberFormatException e) {
            return defaultValue;
        }
    }

    public List<ItemDTO> getAllItems() {
        return cachedItems;
    }

    @SuppressWarnings("unchecked")
    private ItemDTO toItemDTO(ItemConfig ic) {
        try {
            ItemDTO dto = objectMapper.readValue(ic.getConfigData(), ItemDTO.class);
            dto.setId(ic.getItemId());
            return dto;
        } catch (Exception e) {
            log.warn("Failed to parse item config: id={}", ic.getItemId(), e);
            return ItemDTO.builder().id(ic.getItemId()).build();
        }
    }
}
