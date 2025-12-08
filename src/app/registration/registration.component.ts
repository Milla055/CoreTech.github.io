import { Component, DestroyRef, EventEmitter, inject, Output } from '@angular/core';
import { CommonModule } from '@angular/common';
import { AbstractControl, FormControl, FormGroup, ReactiveFormsModule, Validators } from '@angular/forms';
import { of } from 'rxjs';
import { RouterLink } from "@angular/router";

export function mustContainSpecialCharacters(control: AbstractControl) {
  const specialChars = ['?', '.', ':', '#', '/', '@', '&', ',', '!', '=', '-', '_', '%', '$'];

  for (let i = 0; i < specialChars.length; i++) {
    if (control.value.includes(specialChars[i])) return null;
  }
  return { doesNotContainSpecialCharacters: true };
}

function emailIsUnique(control: AbstractControl) {
  if (control.value !== 'test@example.com') {
    return of(null);
  }

  return of({ emailIsNotUnique: true });
}

function usernameIsUnique(control: AbstractControl) {
  if (control.value !== 'fityma123') {
    return of(null);
  }

  return of({ usernameIsNotUnique: true });
}

function passwordIsMatching(control: AbstractControl) {
  if ( control.value.password == control.value.confirmPassword) {
    return of(null);
  }
  return of({passwordIsNotMatching: true});
}

@Component({
  selector: 'app-registration',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, RouterLink],
  templateUrl: './registration.component.html',
  styleUrls: ['./registration.component.css'],
})

export class RegistrationComponent {
  @Output() cancel = new EventEmitter<void>();
  private destroyRef = inject(DestroyRef);
  form = new FormGroup({
    email: new FormControl('', {
      validators: [Validators.email, Validators.required],
      asyncValidators: [emailIsUnique],
    }),
    username: new FormControl('', {
      validators: [Validators.required],
      asyncValidators: [usernameIsUnique],
    }),
    password: new FormControl('', {
      validators: [Validators.required, Validators.minLength(8), mustContainSpecialCharacters],
    }),
    confirmPassword: new FormControl('', {
      validators: [Validators.required],
      asyncValidators: [passwordIsMatching],
    })
  });
passwordIsNotMatching: any;
passwordIsMatching: any;

  get emailIsInvalid() {
  const c = this.form.controls.email;
  return (
    c.touched &&
    !c.pending &&
    c.invalid
  );
}

  get usernameIsInvalid() {
  const c = this.form.controls.username;
  return (
    c.touched &&
    !c.pending &&
    c.invalid
  );
}

  get confirmPasswordIsInvalid() {
    const pass = this.form.controls.password.value;
    const confirm = this.form.controls.confirmPassword.value;
    const touched = this.form.controls.confirmPassword.touched && this.form.controls.confirmPassword.dirty;
    return touched && pass && confirm && pass !== confirm;
  }

  get passwordIsInvalid() {
    return (
      this.form.controls.password.touched &&
      this.form.controls.password.dirty &&
      this.form.controls.password.invalid
    );
  }

  ngOnInit() {
    const savedForm = window.localStorage.getItem('saved-login-form');

    if(savedForm) {
      const loadedForm = JSON.parse(savedForm);
      this.form.patchValue({
        email: loadedForm.email
      })
    }
  }

  closeLogin() {
    this.cancel.emit();
  }

  onSubmit() {
    const enteredEmail = this.form.value.email;
    const enteredPassword = this.form.value.password;

    console.log(enteredEmail, enteredPassword);
  }
}
