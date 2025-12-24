<?php
defined('BASEPATH') or exit('No direct script access allowed');

class Register extends REST_Controller
{

  public function __construct()
  {
    parent::__construct();
    $this->load->model("ModelAuth");
  }

  public function Register_post()
  {
    $data = array(
      'username' => $this->post("username"),
      'password' => password_hash($this->post("password"), PASSWORD_DEFAULT, array("cost" => 10)),
      'jabatan' => $this->post("jabatan"),
      'nama' => $this->post("nama"),
      'tgl_lahir' => $this->post("tgl_lahir"),
      'tinggi_badan' => $this->post("tinggi_badan"),
      'berat_badan' => $this->post("berat_badan"),
      'alamat' => $this->post("alamat"),
      'kecamatan' => $this->post("kecamatan"),
      'kabupaten' => $this->post("kabupaten"),
      'provinsi' => $this->post("provinsi"),
      'jekel' => $this->post("jekel"),
      'no_telp' => $this->post("no_telp"),
      'tgl_daftar' => date("Y-m-d H:i:s"),
      'email' => $this->post("email"),
      'umur' => $this->post("umur"),

    );

    if ($this->db->get_where("user", array('username' => $this->post("username")))->num_rows() < 1) {
      if ($this->db->get_where("user", array('email' => $this->post("email")))->num_rows() < 1) {
        if ($this->db->insert('user', $data)) {
          $message = array(
            'status' => 200,
            'message' => "OK"
          );
        } else {
          $message = array(
            'status' => 500,
            'message' => "INTERNAL_SERVER_ERROR"
          );
        }
      } else {
        $message = array(
          'status' => 502,
          'message' => "Email Sudah Digunakan"
        );
      }
    } else {
      $message = array(
        'status' => 501,
        'message' => "Username Sudah Digunakan"
      );
    }
    $this->response(array('response' => $data, 'message' => $message));
  }
}
