import { Component, DestroyRef, EventEmitter, inject, OnInit, Output } from '@angular/core';
import {
  AbstractControl,
  FormControl,
  FormGroup,
  ReactiveFormsModule,
  Validators,
} from '@angular/forms';
import { Router, RouterLink} from '@angular/router';
import { debounceTime, of } from 'rxjs';
import { AuthService } from '../services/auth.service';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-login',
  imports: [ReactiveFormsModule, RouterLink, CommonModule],
  templateUrl: './login.component.html',
  styleUrl: './login.component.css',
})
export class LoginComponent implements OnInit {
  @Output() cancel = new EventEmitter<void>();
  private destroyRef = inject(DestroyRef);
  private authService = inject(AuthService);
  
  // Jelszó megjelenítés állapota
  showPassword: boolean = false;
  
  form = new FormGroup({
    email: new FormControl('', {
      validators: [Validators.email, Validators.required],
    }),
    password: new FormControl('', {
      validators: [Validators.required,],
    }),
    rememberMe: new FormControl(false),
  });

  constructor(private AuthService: AuthService, private router: Router) {}

  get emailIsInvalid() {
    return (
      this.form.controls.email.touched &&
      this.form.controls.email.dirty &&
      this.form.controls.email.invalid
    );
  }

  get passwordIsInvalid() {
    return (
      this.form.controls.password.touched &&
      this.form.controls.password.dirty &&
      this.form.controls.password.invalid
    );
  }

  // Jelszó megjelenítés/elrejtés váltása
  togglePasswordVisibility(): void {
    this.showPassword = !this.showPassword;
  }

  ngOnInit() {
    const savedForm = window.localStorage.getItem('saved-login-form');

    if(savedForm) {
      const loadedForm = JSON.parse(savedForm);
      this.form.patchValue({
        email: loadedForm.email,
        rememberMe: loadedForm.rememberMe || false
      })
    }

    const subscription = this.form.valueChanges.pipe(debounceTime(500)).subscribe({
      next: (value) => {
        // Only save email if rememberMe is checked
        if (value.rememberMe) {
          window.localStorage.setItem('saved-login-form', JSON.stringify({ 
            email: value.email,
            rememberMe: true
          }));
        } else {
          window.localStorage.removeItem('saved-login-form');
        }
      },
    });

    this.destroyRef.onDestroy(() => subscription.unsubscribe());
  }

  closeLogin() {
    this.cancel.emit();
  }

  onSubmit() {
  if (this.form.invalid) return;
  const finalData = {email:this.form.value.email!, password:this.form.value.password!}

  this.AuthService.login(finalData).subscribe({
    next: (result) => {
      console.log(result);
      // Navigation is now automatic because AuthService handles everything
      this.router.navigate(['/mainpage']);
    },
    error: (err) => {
      console.error('Hiba történt:', err);
      alert('Hibás email vagy jelszó');
    }
  });
}


}