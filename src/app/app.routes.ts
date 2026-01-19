import { Routes } from '@angular/router';
import { LoginComponent } from './login/login.component';
import { RegistrationComponent } from './registration/registration.component';
import { MainpageComponent } from './mainpage/mainpage.component';
import { AboutuspageComponent } from './aboutuspage/aboutuspage.component';
import { ProductcardComponent } from './productcard/productcard.component';

export const routes: Routes = [
  { path: 'login', component: LoginComponent },
  { path: 'registration', component: RegistrationComponent },
  { path: 'mainpage', component: MainpageComponent },
  { path: 'aboutuspage', component: AboutuspageComponent },
  { path: 'productcard', component: ProductcardComponent },
  { path: '', redirectTo: 'login', pathMatch: 'full' }
];