import { Component } from '@angular/core';
import { LoginComponent } from "../login/login.component";

@Component({
  selector: 'app-header',
  imports: [LoginComponent],
  templateUrl: './header.component.html',
  styleUrl: './header.component.css',
})
export class HeaderComponent {
  loginPopup = false;
  onLogin(){
    this.loginPopup = true;
  }
  closeLogin(){
    this.loginPopup = false;
  }
}
