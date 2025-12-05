import { Component, signal } from '@angular/core';
import { LoginComponent } from "./login/login.component";
import { HeaderComponent } from "./header/header.component";
import { RouterOutlet } from '@angular/router';
import { ShopmenuComponent } from "./shopmenu/shopmenu.component";
import { MainpageComponent } from "./mainpage/mainpage.component";
import { RegistrationComponent } from "./registration/registration.component";
import { AdminpageComponent } from "./adminpage/adminpage.component";

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [LoginComponent, HeaderComponent, RouterOutlet, ShopmenuComponent, MainpageComponent, RegistrationComponent, AdminpageComponent],
  templateUrl: './app.html',
  styleUrls: ['./app.css']
})
export class App {
  protected readonly title = signal('vizsgaremek');
}
