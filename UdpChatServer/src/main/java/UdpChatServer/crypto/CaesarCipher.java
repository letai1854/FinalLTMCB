import java.util.HashMap;
import java.util.Map;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class CaesarCipher {
    private static final Logger log = LoggerFactory.getLogger(CaesarCipher.class);

    /**
     * @return A map with characters as keys and their frequencies as values.
     */
    public static Map<Character, Integer> countLetterFrequencies(String text) {
        // Log the input string before counting
        log.debug("Counting frequencies for text: {}", text);
        // log.info("\n\ncount letter: "+text+"\n\n"); // Giữ lại log cũ nếu cần
        if (text == null) {
            log.warn("countLetterFrequencies called with null input, returning empty map.");
            return new HashMap<>();
        }
        Map<Character, Integer> frequencies = new HashMap<>();
        for (char c : text.toCharArray()) {
            frequencies.put(c, frequencies.getOrDefault(c, 0) + 1);
        }
        // Log the resulting frequency map
        log.debug("Frequency count result: {}", frequencies);
        return frequencies;
    }
} 