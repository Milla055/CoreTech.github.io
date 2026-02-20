import { Component, signal } from '@angular/core';
import { RouterOutlet } from '@angular/router';
import { ProductcardComponent } from "./productcard/productcard.component";
import { AboutuspageComponent } from "./aboutuspage/aboutuspage.component";
import { MainpageComponent } from "./mainpage/mainpage.component";
import { RegistrationComponent } from "./registration/registration.component";
import { HeaderComponent } from "./header/header.component";


@Component({
  selector: 'app-root',
  standalone: true,
  imports: [RouterOutlet ],
  templateUrl: './app.html',
  styleUrls: ['./app.css']
})
export class App {
  protected readonly title = signal('vizsgaremek');
}
