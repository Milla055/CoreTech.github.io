import { Component, signal } from '@angular/core';
import { LoginComponent } from "./login/login.component";
import { HeaderComponent } from "./header/header.component";
import { RouterOutlet } from '@angular/router';
import { ShopmenuComponent } from "./shopmenu/shopmenu.component";

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [LoginComponent, HeaderComponent, RouterOutlet, ShopmenuComponent],
  templateUrl: './app.html',
  styleUrls: ['./app.css']
})
export class App {
  protected readonly title = signal('vizsgaremek');
}
