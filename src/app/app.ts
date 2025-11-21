import { Component, signal } from '@angular/core';
import { LoginComponent } from "./login/login.component";
import { HeaderComponent } from "./header/header.component";

@Component({
  selector: 'app-root',
  imports: [LoginComponent, HeaderComponent],
  templateUrl: './app.html',
  styleUrl: './app.css'
})
export class App {
  protected readonly title = signal('vizsgaremek');
}
