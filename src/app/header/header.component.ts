import { Component } from '@angular/core';
import { LoginComponent } from "../login/login.component";
import { ShopmenuComponent } from "../shopmenu/shopmenu.component";

@Component({
  selector: 'app-header',
  imports: [LoginComponent, ShopmenuComponent],
  templateUrl: './header.component.html',
  styleUrl: './header.component.css',
})
export class HeaderComponent {
  loginPopup = false;
  shopMenu = false;
  
  onLogin(){
    this.loginPopup = true;
  }
  closeLogin(){
    this.loginPopup = false;
  }

  toggleShopMenu(){
    this.shopMenu = true;
  }
  closeShopMenu(){
    this.shopMenu = false;
  }
}
