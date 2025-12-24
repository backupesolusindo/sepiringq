<?php
defined('BASEPATH') or exit('No direct script access allowed');

class UpdateProfil extends REST_Controller
{

    public function __construct()
    {
        parent::__construct();
        $this->load->model("ModelAuth");
    }

    public function UpdateProfil_post()
    {
        // Mengambil id_user dari data yang dikirim dalam permintaan POST
        $id_user = $this->post("id_user");

        $data = array(
            'username' => $this->post("username"),
            //'password' => password_hash($this->post("password"), PASSWORD_DEFAULT, array("cost" => 10)),
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
            'email' => $this->post("email"),
            'umur' => $this->post("umur"),
        );

        // Lakukan validasi data di sini jika diperlukan

        if ($this->db->get_where("user", array('id_user' => $id_user))->num_rows() > 0) {
            if ($this->db->update('user', $data, array('id_user' => $id_user))) {
                $message = array(
                    'status' => 200,
                    'message' => "Data berhasil diperbarui"
                );
            } else {
                $message = array(
                    'status' => 500,
                    'message' => "INTERNAL_SERVER_ERROR"
                );
            }
        } else {
            $message = array(
                'status' => 404,
                'message' => "Profil tidak ditemukan"
            );
        }
        $this->response(array('response' => $data, 'message' => $message));
    }
}