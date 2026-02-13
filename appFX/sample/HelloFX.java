import javafx.application.Application;
import javafx.geometry.Insets;
import javafx.geometry.Pos;
import javafx.scene.Scene;
import javafx.scene.control.Label;
import javafx.scene.image.Image;
import javafx.scene.image.ImageView;
import javafx.scene.layout.VBox;
import javafx.stage.Stage;
import javafx.scene.text.Font;

public class HelloFX extends Application {

    @Override
    public void start(Stage stage) {
        System.out.println("StartFX");
        String javaVersion = System.getProperty("java.version");
        String javafxVersion = System.getProperty("javafx.version");

        ImageView imageView = new ImageView(new Image(HelloFX.class.getResourceAsStream("openduke.png")));
        imageView.setFitHeight(200);
        imageView.setPreserveRatio(true);

        Label label = new Label("Hello, JavaFX " + javafxVersion + ", running on Java " + javaVersion +
                " and OS name:arch :: " + System.getProperty("os.name") + ":" + System.getProperty("os.arch"));
        label.setWrapText(true);
        label.setAlignment(Pos.CENTER);
        label.setFont(new Font(20));
        imageView.setOnMouseClicked(_ -> label.setText(label.getText() + "\nClick!"));

        VBox root = new VBox(20, imageView, label);
        root.setAlignment(Pos.TOP_CENTER);
        root.setPadding(new Insets(100, 20, 20, 20));
        Scene scene = new Scene(root, 640, 480);
        stage.setScene(scene);
        stage.show();
    }

    public static void main(String[] args) {
        System.out.println("Hello JavaFX: " + System.getProperty("os.name") + ":" + System.getProperty("os.arch"));
        try { launch(args); } catch (Throwable t) { t.printStackTrace(); }
    }
}