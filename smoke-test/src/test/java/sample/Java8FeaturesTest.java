package sample;

import org.junit.jupiter.api.Test;
import java.time.LocalDate;
import java.util.Arrays;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

public class Java8FeaturesTest {

    @Test
    public void testJavaVersionRuntime() {
        String version = System.getProperty("java.version");
        System.out.println("Running test on Java runtime version: " + version);
        assertTrue(version.startsWith("1.8."), "Expected Java 8 runtime (1.8.x), got: " + version);
    }

    @Test
    public void testStreamsAndLambdas() {
        Java8Features features = new Java8Features();
        List<String> input = Arrays.asList("apple", "", "banana", null, "cherry");
        List<String> result = features.filterAndUppercase(input);

        assertEquals(Arrays.asList("APPLE", "BANANA", "CHERRY"), result);
    }

    @Test
    public void testOptional() {
        Java8Features features = new Java8Features();
        List<String> list = Arrays.asList("alpha", "beta", "gamma");

        assertEquals("beta", features.findFirstMatching(list, "be"));
        assertEquals("DEFAULT", features.findFirstMatching(list, "zeta"));
    }

    @Test
    public void testJavaTime() {
        Java8Features features = new Java8Features();
        LocalDate date = LocalDate.of(2026, 11, 7);
        assertEquals(2026, features.getYear(date));
    }
}
