package sample;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

/**
 * Sample class utilizing Java 8 features (Streams, Lambdas, Optional, java.time)
 * to verify compilation and execution in a true Java 8 runtime.
 */
public class Java8Features {

    public List<String> filterAndUppercase(List<String> items) {
        return items.stream()
                .filter(s -> s != null && !s.isEmpty())
                .map(String::toUpperCase)
                .collect(Collectors.toList());
    }

    public String findFirstMatching(List<String> items, String prefix) {
        Optional<String> match = items.stream()
                .filter(s -> s != null && s.startsWith(prefix))
                .findFirst();
        return match.orElse("DEFAULT");
    }

    public int getYear(LocalDate date) {
        return date.getYear();
    }
}
